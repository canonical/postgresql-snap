#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]
  then echo "Need to be root to switch to snap _daemon_ user."
  exit
fi

# Filter out unwanted args
REMOVE_IDX=()
CLUSTER_ARGS=("$@")
INITDB_ARGS=()
for ((i=0; i<"${#CLUSTER_ARGS[@]}"; ++i)); do
    case ${CLUSTER_ARGS[i]} in
        -u) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: User must be _daemon_! Skipping";; 
        -g) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: Group must be root! Skipping";; 
        -s) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: Socket dir must be default! Skipping";; 
        -d) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: Data dir must be default! Skipping";; 
        -l) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: Logfile must be default! Skipping";; 
        --start) REMOVE_IDX=($((i)) "${REMOVE_IDX[@]}"); echo "WARNING: New cluster cannot be started! Skipping";; 
        --start-conf) REMOVE_IDX=($((i+1)) $((i)) "${REMOVE_IDX[@]}"); echo "WARNING: Start conf must be manual! Skipping";; 
        --) INITDB_ARGS=("${CLUSTER_ARGS[@]:i+1}");CLUSTER_ARGS=("${CLUSTER_ARGS[@]::i}");;
    esac
done

for ((i=0; i<"${#REMOVE_IDX[@]}"; ++i)); do
    unset "CLUSTER_ARGS[REMOVE_IDX[i]]";
done

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)
NAME="${CLUSTER_ARGS[-1]}"

if [ "$PG_MAJOR_VER" -ne "${CLUSTER_ARGS[-2]}" ]
  then echo "Cannot create $1 cluster on $PG_MAJOR_VER snap."
  exit
fi

# Check for necessary initdb args
for ((i=0; i<"${#INITDB_ARGS[@]}"; ++i)); do
    case ${INITDB_ARGS[i]} in
        -U | --username | --username=*) PG_USER=true;;
        --auth-host | --auth-host=*) HOST_AUTH=true;; 
        --auth-local | --auth-local=*) LOCAL_AUTH=true;;
        -A | --auth | --auth=*) HOST_AUTH=true; LOCAL_AUTH=true;;
    esac
done

if [ -z "$PG_USER" ]; then
    INITDB_ARGS+=('-U')
    INITDB_ARGS+=('postgres')
fi

if [ -z "$LOCAL_AUTH" ]; then
    INITDB_ARGS+=('--auth-local=trust')
fi

if [ -z "$HOST_AUTH" ]; then
    INITDB_ARGS+=('--auth-host=scram-sha-256')
fi


# TODO figure out local-auth
"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_createcluster -u _daemon_ -g root --start-conf=manual "${CLUSTER_ARGS[@]}" -- "${INITDB_ARGS[@]}"

# Inject LD_LIBRARY_PATH in the env file
echo "LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" | "$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- tee -a  "$SNAP_COMMON/etc/postgresql/$PG_MAJOR_VER/$NAME/environment"

echo "The cluster can be started with: 'postgresql.ctlcluster --skip-systemctl-redirect --foreground $PG_MAJOR_VER $NAME start'"
