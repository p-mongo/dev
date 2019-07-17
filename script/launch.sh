do_mlaunch() {
  echo "Base port: $port"
  
  # 1024 was insufficient with retry reads on by default
  ulimit -n 2000
  if test -d "$dbdir"; then
    if test -n "$1"; then
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
    if echo "$version" |grep -Eq '^(3.[46]|4)'; then
      params="$params --wiredTigerCacheSizeGB 0.25"
    elif echo "$version" |grep -Eq '^3'; then
      params="$params --wiredTigerCacheSizeGB 1"
    fi
    case "$version" in
      4.1*)
        # ttlMonitorEnabled cannot be used when launching a sharded cluster.
        if ! echo "$0" |grep -q sharded; then
          params="$params --setParameter ttlMonitorEnabled=false"
        fi
        # https://github.com/rueckstiess/mtools/issues/683
        params="$params --wiredTigerEngineConfigString 'log=(prealloc=false,file_max=20MB)'"
        # not accepted by mongos
        # https://jira.mongodb.org/browse/DOCS-12806
        #params="$params --setParameter transactionLifetimeLimitSeconds=15"
        # also https://github.com/rueckstiess/mtools/issues/696
        ;;
    esac

    mlaunch $launchargs --dir $dbdir $params \
      --setParameter enableTestCommands=1 \
      --filePermissions 0666 \
      --binarypath $bindir --port $port "$@"
  fi
  
  chmod -R go+rwX "$dbdir"
}

# --maxConns 200
#     --storageEngine ephemeralForTest \

# MONGODB_URI=mongodb://127.0.0.1:27100,127.0.0.1:27001/\?replicaSet=ruby-driver-rs bs
