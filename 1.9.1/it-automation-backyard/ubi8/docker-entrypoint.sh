#!/bin/bash -ex

if [ -e /exastro/ita-root/confs/commonconfs ]; then

  echo -ne "mysql:dbname=ita_db;host=${EXASTRO_ITA_DB_SERVICE_NAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_connection_string.txt
  echo -ne "${EXASTRO_ITA_DB_USERNAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_username.txt
  echo -ne "${EXASTRO_ITA_DB_PASSWORD}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_password.txt

fi

# Execute command
exec "$@"
