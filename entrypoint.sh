#!/usr/bin/env bash
[ "$DEBUG" == 'true' ] && set -x 

# Kill container
trap 'kill $1; exit 0' SIGTERM

# Variables
SSH_SHELL="/bin/sh"
USER_HOME="/users"
SSH_KEY_DIR="/keys"
SSH_GROUP="sshjail"
SSH_RESTRICT_EXECUTABLE="/usr/local/bin/restrict"
EXTERNAL_USER_NAME="external"

if [ ! -n "${USERS}" ]; then
    echo "ERROR: No users defined!"
    exit -1
fi

if [ ! -n "${EXTERNAL_USER}" ]; then
    echo "ERROR: No external user defined!"
    exit -1
fi

# Add external user
IFS=':' read -ra UA <<< "$EXTERNAL_USER"
EXTERNAL_UID=${UA[0]}
EXTERNAL_GID=${UA[1]}

if [ ${#UA[*]} -ge 2 ]; then
    EXTERNAL_GID=${UA[1]}
    groupdel ${EXTERNAL_USER_NAME}
    groupadd -o -g ${EXTERNAL_GID} ${EXTERNAL_USER_NAME}
    GID_ARGS="--gid ${EXTERNAL_GID}"
else
    EXTERNAL_GID=${EXTERNAL_USER_NAME}
    GID_ARGS="-U"
fi

# Add external user
useradd -M \
    --uid $EXTERNAL_UID $GID_ARGS \
    -s $SSH_SHELL \
    ${EXTERNAL_USER_NAME}

# User processing
USERS_SEPERATED=$(echo $USERS | tr "," "\n")
GROUP_COUNT=0
for USER in $USERS_SEPERATED; do
    # Seperate arguments
    IFS=':' read -ra UA <<< "$USER"
    _NAME=${UA[0]}
    _UID=${UA[1]}
    if [ ${#UA[*]} -ge 3 ]; then
        _GID=${UA[2]}
        groupdel group_$GROUP_COUNT
        groupadd -o -g $_GID group_$GROUP_COUNT
        (( GROUP_COUNT++ ))
        GID_ARGS="--gid $_GID"
    else
        _GID=$_UID
        GID_ARGS="-U"
    fi

    # Create user
    # NOTE: Password must be set otherwise SSH would refuse to work
    if id "$1" &>/dev/null; then
        userdel -r $_NAME
    fi

    useradd --base-dir "$USER_HOME" \
        --uid $_UID $GID_ARGS \
        -G $SSH_GROUP \
        -s $SSH_SHELL \
        -p password $_NAME

    if [ ! -f $USER_HOME/$_NAME ]; then
      mkdir $USER_HOME/$_NAME
      chown $EXTERNAL_UID:$EXTERNAL_GID $USER_HOME/$_NAME
    fi 

    # Check for keys
    if [ ! -f "$SSH_KEY_DIR/$_NAME.pub" ]; then
        echo "SSH key for user $_NAME missing! Aborting..."
        exit -1
    fi

    # FUSE dark magic bind mount
    bindfs -u $_UID -g $_GID --create-for-user=${EXTERNAL_USER_NAME} /users/$user /users/$user

    # Create SSH stuff
    if [ ! -f $USER_HOME/$_NAME/.ssh ]; then
        mkdir $USER_HOME/$_NAME/.ssh
    fi

    # Add SSH restrictions
    echo -n \
        "command=\"$SSH_RESTRICT_EXECUTABLE \$SSH_ORIGINAL_COMMAND\" " > \
        $USER_HOME/$_NAME/.ssh/authorized_keys

    # Add user key
    cat $SSH_KEY_DIR/$_NAME.pub >> \
        $USER_HOME/$_NAME/.ssh/authorized_keys

    chmod 744 $USER_HOME/$_NAME/.ssh/authorized_keys
    chown root:root $USER_HOME/$_NAME/.ssh/authorized_keys
done 

# Check if host keys exist; if so, don't generate new ones
for i in dsa ecdsa ed25519 rsa; do
    if [ -f /etc/ssh/ssh_host_${i}_key ] && [ -f /etc/ssh/ssh_host_${i}_key.pub ]; then
        SSH_HOST_KEY_EXISTS=1
        break;
    fi
done

# Generate host keys
[ -n $SSH_HOST_KEY_EXISTS ] && /usr/bin/ssh-keygen -A

SSH_FLAGS=""
if [ "$DEBUG" == 'true' ]; then
    SSH_FLAGS="$SSH_FLAGS -d"
fi

# Start ssh server
/usr/sbin/sshd -D $SSH_FLAGS

