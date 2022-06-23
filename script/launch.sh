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

fix_dbdir_perms() {
  if test -d "$dbdir"; then
    echo "Setting permissions on $dbdir to wide open"
    chmod -R go+rwX "$dbdir"
  fi
}

do_mlaunch() {
  echo "Base port: $port"
  
  trap fix_dbdir_perms EXIT
  
  # 1024 was insufficient with retry reads on by default
  if test `ulimit -n` -le 4010; then
    ulimit -n 4010
  fi
  if test -f "$dbdir"/.mlaunch_startup; then
    if test "$1" = rm; then
      mlaunch stop --dir "$dbdir"
      rm -rf "$dbdir"
      for i in `seq 0 5`; do
        p=`expr $port + $i`
        pid=`lsof -iTCP:$p -t`
        if test -n "$pid"; then
          echo "Kill $pid for $p"
          kill -9 "$pid" || true
        fi
      done
      return
    elif test "$1" = restart; then
      for f in `find "$dbdir" -name \*pid`; do
        kill -9 `cat "$f"`
      done
      for kill_port in `seq $port $(expr $port + 9)`; do
        ps awwxu |grep $kill_port |awk '{print $2}' |xargs kill -9 2>/dev/null || true
      done
      mlaunch start --dir "$dbdir"
    elif test -n "$1" && ! echo "$1" |grep -q ^-; then
      cmd="$1"
      shift
      mlaunch $cmd --dir "$dbdir" "$@"
    else
      mlaunch start --dir "$dbdir"
    fi
  else
    if test `basename "$bindir"` = bin; then
      version=$(basename $(dirname "$bindir") |tr -d .)
    else
      version=$(basename "$bindir" |tr -d .)
    fi
    params=
    if test $version -ge 32; then
      params="$params --setParameter diagnosticDataCollectionEnabled=false"
    fi
    if ! echo "$launchargs" |grep -q -- --wiredTigerCacheSizeGB; then
      if test $version -ge 34; then
        params="$params --wiredTigerCacheSizeGB 0.25"
      elif test $version -ge 30; then
        params="$params --wiredTigerCacheSizeGB 1"
      fi
    fi
    if test $version -ge 36; then
      params="$params --setParameter honorSystemUmask=true"
    fi
    if test $version -eq 40; then
      params="$params --networkMessageCompressors snappy,zlib"
    fi
    if test $version -ge 42; then
      # ttlMonitorEnabled cannot be used when launching a sharded cluster.
      if ! echo "$0" |grep -q sharded; then
        params="$params --setParameter ttlMonitorEnabled=false"
      fi
      # https://github.com/rueckstiess/mtools/issues/683
      params="$params --wiredTigerEngineConfigString 'log=(prealloc=false,file_max=20MB),cache_size=256M'"
      # not accepted by mongos
      # https://jira.mongodb.org/browse/DOCS-12806
      #params="$params --setParameter transactionLifetimeLimitSeconds=15"
      # also https://github.com/rueckstiess/mtools/issues/696
      params="$params --networkMessageCompressors zstd,snappy,zlib"
    fi
    if ! echo "$launchargs" |grep -q enableTestCommands; then
      params="$params --setParameter enableTestCommands=1"
    fi

    announce mlaunch $launchargs --dir $dbdir $params \
      --filePermissions 0666 \
      --binarypath $bindir --port $port "$@"
  fi
}

# --maxConns 200
#     --storageEngine ephemeralForTest \

# MONGODB_URI=mongodb://127.0.0.1:27100,127.0.0.1:27001/\?replicaSet=ruby-driver-rs bs
