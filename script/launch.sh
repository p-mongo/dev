do_mlaunch() {
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
  # 4.1 only
  #    --setParameter ttlMonitorEnabled=false \
  # https://github.com/rueckstiess/mtools/issues/683
  #    --wiredTigerEngineConfigString "log=(prealloc=false,file_max=20MB)" \
    mlaunch $launchargs --dir $dbdir \
      --wiredTigerCacheSizeGB 0.25 --setParameter enableTestCommands=1 \
      --setParameter diagnosticDataCollectionEnabled=false \
      --filePermissions 0666 \
      --binarypath $bindir --port $port "$@"
  fi
  
  chmod -R go+rwX "$dbdir"
}

# --maxConns 200
#     --storageEngine ephemeralForTest \

# MONGODB_URI=mongodb://127.0.0.1:27100,127.0.0.1:27001/\?replicaSet=ruby-driver-rs bs
