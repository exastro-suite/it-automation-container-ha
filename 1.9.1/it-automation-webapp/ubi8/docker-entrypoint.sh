#!/bin/bash -ex

##############################################################################
# Certificate
EXASTRO_ITA_DOMAIN=exastro-it-automation.local
CERTIFICATE_FILE=${EXASTRO_ITA_DOMAIN}.crt
PRIVATE_KEY_FILE=${EXASTRO_ITA_DOMAIN}.key
CSR_FILE=${EXASTRO_ITA_DOMAIN}.csr


##############################################################################
# DBConnect

if [ -e /exastro ]; then
  echo -ne "mysql:dbname=ita_db;host=${EXASTRO_ITA_DB_SERVICE_NAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_connection_string.txt
  echo -ne "${EXASTRO_ITA_DB_USERNAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_username.txt
  echo -ne "${EXASTRO_ITA_DB_PASSWORD}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > /exastro/ita-root/confs/commonconfs/db_password.txt

##############################################################################
# Certificate
  cd /etc/pki/tls/certs/
  echo "subjectAltName=DNS:${EXASTRO_ITA_DOMAIN}" > san.txt

  openssl genrsa 2048 > ${PRIVATE_KEY_FILE}
  openssl req -new -sha256 -key ${PRIVATE_KEY_FILE} -out ${CSR_FILE} -subj "/CN=${EXASTRO_ITA_DOMAIN}"

  openssl x509 -days 3650 -req -signkey ${PRIVATE_KEY_FILE} -extfile san.txt < ${CSR_FILE} > ${CERTIFICATE_FILE}

  rm -f ${CSR_FILE}
  rm -f san.txt

fi

# Execute command
exec "$@"
