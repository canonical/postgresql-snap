#!/bin/bash
set -e

if [ "${EUID}" != "0" ]; then
  echo "Error: run it as root (to utilize snap user _daemon_)." >&2
  exit 1
fi

# Filter out unwanted args
CLUSTER_ARGS=()
INITDB_ARGS=()
SKIP_NEXT=0

while [[ $# -gt 0 ]]; do
    if (( SKIP_NEXT )); then
        SKIP_NEXT=0
        shift
        continue
    fi

    case "$1" in
        -u)
            echo "WARNING: User must be _daemon_! Skipping"
            SKIP_NEXT=1
            ;;
        -g)
            echo "WARNING: Group must be root! Skipping"
            SKIP_NEXT=1
            ;;
        -s)
            echo "WARNING: Socket dir must be default! Skipping"
            SKIP_NEXT=1
            ;;
        -d)
            echo "WARNING: Data dir must be default! Skipping"
            SKIP_NEXT=1
            ;;
        -l)
            echo "WARNING: Logfile must be default! Skipping"
            SKIP_NEXT=1
            ;;
        --start)
            echo "WARNING: New cluster cannot be started! Skipping"
            ;;
        --start-conf)
            echo "WARNING: Start conf must be manual! Skipping"
            SKIP_NEXT=1
            ;;
        --)
            shift
            INITDB_ARGS=("$@")
            break
            ;;
        *)
            CLUSTER_ARGS+=("$1")
            ;;
    esac
    shift
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
echo "LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" | sed "s#/$SNAP_REVISION/#/current/#g" | "$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- tee -a  "$SNAP_COMMON/etc/postgresql/$PG_MAJOR_VER/$NAME/environment"

echo "The cluster can be started with: 'postgresql.ctlcluster --skip-systemctl-redirect $PG_MAJOR_VER $NAME start'"
