do_mlaunch() {
  if test -d "$dbdir"; then
    if test -n "$1"; then
      cmd=$1
      shift
      mlaunch $cmd --dir $dbdir "$@"
    else
      mlaunch start --dir $dbdir
    fi
  else
    mlaunch $launchargs --dir $dbdir \
      --wiredTigerCacheSizeGB 0.25 --setParameter enableTestCommands=1 \
      --setParameter ttlMonitorEnabled=false \
      --setParameter diagnosticDataCollectionEnabled=false \
      --wiredTigerEngineConfigString "log=(prealloc=false,file_max=20MB)" \
      --binarypath $bindir --port $port "$@"
  fi
}

#     --storageEngine ephemeralForTest \

# MONGODB_URI=mongodb://127.0.0.1:27100,127.0.0.1:27001/\?replicaSet=ruby-driver-rs bs
