# Configure log verbosity:
# https://docs.mongodb.com/manual/reference/log-messages/#log-messages-configure-verbosity
#
# Reduce noop writer interval in sharded clusters to make tests run faster
# (presumably at the cost of more cpu usage overall):
# https://github.com/mongodb/specifications/pull/785/files

announce() {
  echo "Running $@"
  eval "$@"
}

do_mlaunch() {
  echo "Base port: $port"
  
  # 1024 was insufficient with retry reads on by default
  if test `ulimit -n` -le 2000; then
    ulimit -n 2000
  fi
  if test -f "$dbdir"/.mlaunch_startup; then
    if test "$1" = rm; then
      rm -rf "$dbdir"
      return
    elif test "$1" = restart; then
      for f in `find "$dbdir" -name \*pid`; do
        kill -9 `cat "$f"`
      done
      for kill_port in `seq $port $(expr $port + 9)`; do
        ps awwxu |grep $kill_port |awk '{print $2}' |xargs kill -9 2>/dev/null || true
      done
      mlaunch start --dir "$dbdir"
    elif test -n "$1"; then
      cmd="$1"
      shift
      mlaunch $cmd --dir "$dbdir" "$@"
    else
      mlaunch start --dir "$dbdir"
    fi
  else
    if test `basename "$bindir"` = bin; then
      version=$(basename $(dirname "$bindir"))
    else
      version=$(basename "$bindir")
    fi
    params=
    if echo "$version" |grep -Eq '^(3.[246]|4)'; then
      params="$params --setParameter diagnosticDataCollectionEnabled=false"
    fi
    if ! echo "$launchargs" |grep -q -- --wiredTigerCacheSizeGB; then
      if echo "$version" |grep -Eq '^(3.[46]|4)'; then
        params="$params --wiredTigerCacheSizeGB 0.25"
      elif echo "$version" |grep -Eq '^3'; then
        params="$params --wiredTigerCacheSizeGB 1"
      fi
    fi
    if echo "$version" |grep -Eq '^(3.6|4)'; then
      params="$params --setParameter honorSystemUmask=true"
    fi
    if echo "$version" |grep -Eq '^(4.[24])'; then
      # ttlMonitorEnabled cannot be used when launching a sharded cluster.
      if ! echo "$0" |grep -q sharded; then
        params="$params --setParameter ttlMonitorEnabled=false"
      fi
      # https://github.com/rueckstiess/mtools/issues/683
      params="$params --wiredTigerEngineConfigString 'log=(prealloc=false,file_max=20MB),cache_size=64M'"
      # not accepted by mongos
      # https://jira.mongodb.org/browse/DOCS-12806
      #params="$params --setParameter transactionLifetimeLimitSeconds=15"
      # also https://github.com/rueckstiess/mtools/issues/696
    fi
    if ! echo "$launchargs" |grep -q enableTestCommands; then
      params="$params --setParameter enableTestCommands=1"
    fi

    announce mlaunch $launchargs --dir $dbdir $params \
      --filePermissions 0666 \
      --binarypath $bindir --port $port "$@"
  fi
  
  chmod -R go+rwX "$dbdir"
}

# --maxConns 200
#     --storageEngine ephemeralForTest \

# MONGODB_URI=mongodb://127.0.0.1:27100,127.0.0.1:27001/\?replicaSet=ruby-driver-rs bs
