#!/bin/bash -e

##############################################################################
# Initialize volume

initialize_volume() {
    local VOLUME_TYPE=$1
    local VOLUME_NAME=exastro-${VOLUME_TYPE}-volume
    local VOLUME_PATH=/${VOLUME_NAME}
    local MARKER_FILE_PATH=${VOLUME_PATH}/.initialized
    local ARCHIVE_FILE_PATH=/exastro-initial-volume-archive/${VOLUME_NAME}.tar.gz

    if [ ! -e "${MARKER_FILE_PATH}" ]; then
        echo "Volume is not initialized. (type=${VOLUME_TYPE})"

        if [ -f "$ARCHIVE_FILE_PATH" ]; then
            echo "Initialize volume. (type=${VOLUME_TYPE})"

            install --directory --mode=777 ${VOLUME_PATH}   # Alternative to mkdir
            tar zxvf ${ARCHIVE_FILE_PATH} -C ${VOLUME_PATH}

            if [ $? -eq 0 ]; then
                echo "Volume initialization succeeded.  (type=${VOLUME_TYPE})"
                touch ${MARKER_FILE_PATH}
            else
                echo "Volume initialization failed.  (type=${VOLUME_TYPE})"
            fi
        fi
    else
        echo "Volume is already initialized. (type=${VOLUME_TYPE})"
    fi
}

function initialize_volumes() {
    # Initialize file volume
    if [ ${EXASTRO_AUTO_FILE_VOLUME_INIT:-false} = "true" ]; then
        echo "Auto file volume initialization is enabled."
        initialize_volume "file"
    fi
    
    # Initialize database volume
    if [ ${EXASTRO_AUTO_DATABASE_VOLUME_INIT:-false} = "true" ]; then
        echo "Auto database volume initialization is enabled."
        initialize_volume "database"
    fi
}


##############################################################################
# Copy config files

declare -A CONFIG_FILES=(
    ["EXASTRO_ITA_DB_CONNECTION_STRING_FILE"]="${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_connection_string.txt"
    ["EXASTRO_ITA_DB_USERNAME_FILE"]="${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_username.txt"
    ["EXASTRO_ITA_DB_PASSWORD_FILE"]="${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_password.txt"
)

function copy_config_files() {
    local KEY
    for KEY in "${!CONFIG_FILES[@]}"; do
        if [ -z "${!KEY+undefined}" ]; then
            echo "copy_config_files: ${KEY} is undefined:"
        else
            echo "copy_config_files: ${KEY} is defined: ${!KEY}"
        fi
        
        local SRC_CONFIG_FILE=${!KEY}
        echo "copy_config_files: src ... ${SRC_CONFIG_FILE}"
    
        local DST_CONFIG_FILE="${CONFIG_FILES[${KEY}]}"
        echo "copy_config_files: dst ... ${DST_CONFIG_FILE}"
    
        if [ -f "${SRC_CONFIG_FILE}" ]; then
            echo "copy_config_files: copying"
            cp "${SRC_CONFIG_FILE}" "${DST_CONFIG_FILE}"
        fi
    done
}


##############################################################################
# Main

echo "entry point parameters ... $@"

if [ -d /exastro ]; then    # Exastro IT Automation has been installed.
    initialize_volumes
    copy_config_files
fi

# Execute command
exec "$@"
