#!/bin/bash -ex

##############################################################################
# Download Exastro IT Automation Installer

curl -SL ${EXASTRO_ITA_INSTALLER_URL} | tar -xzC ${EXASTRO_ITA_UNPACK_BASE_DIR}


##############################################################################
# Update all installed packages

dnf update -y

##############################################################################
# Builda
##############################################################################
# Certificate
EXASTRO_ITA_DOMAIN=`hostname`
CERTIFICATE_FILE=${EXASTRO_ITA_DOMAIN}.crt
PRIVATE_KEY_FILE=${EXASTRO_ITA_DOMAIN}.key
CSR_FILE=${EXASTRO_ITA_DOMAIN}.csr

##############################################################################
# Set system locale and system timezone
dnf -y --enablerepo=appstream install langpacks-ja
dnf -y --enablerepo=appstream reinstall langpacks-en
localectl set-locale "LANG=en_US.UTF-8"

timedatectl set-timezone Asia/Tokyo

##############################################################################
# Python interpreter warning issue (container only)
#   see https://docs.ansible.com/ansible/2.10/reference_appendices/interpreter_discovery.html

find ${EXASTRO_ITA_UNPACK_BASE_DIR} | grep -E "/ansible.cfg$" | xargs sed -i -E 's/^\[defaults\]$/[defaults\]\ninterpreter_python=auto_silent/'

#sizai_deploy
cd ${EXASTRO_ITA_UNPACK_BASE_DIR}
find it-automation-${EXASTRO_ITA_VER} -type f | xargs -I{} sed -i -e "s:%%%%%ITA_DIRECTORY%%%%%:${EXASTRO_ITA_INSTALL_DIR}:g" {}

#apache_install
yum install -y httpd mod_ssl
systemctl enable httpd

#php_install
yum install -y yum-utils
yum install -y epel-release
yum config-manager --set-enabled powertools

yum install -y php php-bcmath php-cli php-ldap php-mbstring php-mysqlnd php-pear php-pecl-zip php-process php-snmp php-xml zip telnet mailx unzip php-json php-gd python3 php-devel libyaml make sudo crontabs libyaml-devel

pear install HTML_AJAX-beta

ln -s /usr/share/pear-data/HTML_AJAX/js /usr/share/pear/HTML/js

pecl channel-update pecl.php.net

echo "" | pecl install YAML

mkdir -p /usr/share/php/vendor

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin

/usr/bin/composer.phar require "phpoffice/phpspreadsheet":"1.14.1"

mv vendor /usr/share/php/

#php_setting
\cp -pf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc/php.ini /etc/
\cp -pf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc_php-fpm.d/www.conf /etc/php-fpm.d/

#sudoers_setting
cat << EOS > /etc/sudoers.d/it-automation
daemon ALL=(ALL) NOPASSWD:ALL
apache ALL=(ALL) NOPASSWD:ALL
EOS

chmod 440 /etc/sudoers.d/it-automation

#mount_point
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/menus
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webconfs
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs
mkdir -m 777 ${EXASTRO_ITA_INSTALL_DIR}/ita_sessions

mkdir -p /exastro-file-volume/data_relay_storage/ansible_driver
mkdir -p /exastro-file-volume/data_relay_storage/conductor
mkdir -p /exastro-file-volume/data_relay_storage/symphony
mkdir -p /exastro-file-volume/ita_sessions
mkdir -p /exastro-file-volume/ita-root/temp
mkdir -p /exastro-file-volume/ita-root/uploadfiles
mkdir -p /exastro-file-volume/ita-root/webroot/menus/sheets
mkdir -p /exastro-file-volume/ita-root/webroot/menus/users
mkdir -p /exastro-file-volume/ita-root/webconfs/sheets
mkdir -p /exastro-file-volume/ita-root/webconfs/users

#ita_install
\cp -rpf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-contents/ita-root/* ${EXASTRO_ITA_INSTALL_DIR}/ita-root
\cp -rpf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-confs/* ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs

ln -s /exastro-file-volume/data_relay_storage/ansible_driver ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/ansible_driver
ln -s /exastro-file-volume/data_relay_storage/conductor ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/conductor
ln -s /exastro-file-volume/data_relay_storage/symphony ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/symphony

ln -s /exastro-file-volume/ita_sessions ${EXASTRO_ITA_INSTALL_DIR}/ita_sessions
ln -s /exastro-file-volume/ita-root/temp ${EXASTRO_ITA_INSTALL_DIR}/ita-root/temp
ln -s /exastro-file-volume/ita-root/uploadfiles ${EXASTRO_ITA_INSTALL_DIR}/ita-root/uploadfiles
ln -s /exastro-file-volume/ita-root/webroot/menus/sheets ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/menus/sheets
ln -s /exastro-file-volume/ita-root/webroot/menus/users ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/menus/users
ln -s /exastro-file-volume/ita-root/webconfs/sheets ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webconfs/sheets
ln -s /exastro-file-volume/ita-root/webconfs/users ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webconfs/users

#mkdir_create_dir_list.txt
while read line
do
  mkdir -p ${EXASTRO_ITA_INSTALL_DIR}${line};
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/create_dir_list.txt

#chmod_755_list.txt
while read line
do
  chmod 755 ${EXASTRO_ITA_INSTALL_DIR}${line};
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/755_list.txt

#chmod_777_list.txt
while read line
do
  chmod 777 ${EXASTRO_ITA_INSTALL_DIR}${line};
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/777_list.txt

mv ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/uploadfiles /exastro-file-volume/ita-root/webroot
ln -s /exastro-file-volume/ita-root/webroot/uploadfiles ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/uploadfiles

cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_base ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_createparam ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_hostgroup ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_ansible-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_cobbler-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_terraform-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.

#db_connect_setting
echo -ne "mysql:dbname=ita_db;host=${EXASTRO_ITA_DB_CONTAINER_NAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_connection_string.txt

echo -ne "${EXASTRO_ITA_DB_USERNAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_username.txt

echo -ne "${EXASTRO_ITA_DB_PASSWORD}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_password.txt


#apache_setting
yum install -y expect

echo "subjectAltName=DNS:${EXASTRO_ITA_DOMAIN}" > /tmp/san.txt
openssl genrsa 2048 > /tmp/${PRIVATE_KEY_FILE}

expect -c "
set timeout -1
spawn openssl req -new -key /tmp/${PRIVATE_KEY_FILE} -out /tmp/${CSR_FILE}
expect \"Country Name\"
send \"JP\\r\"
expect \"State or Province Name\"
send \"\\r\"
expect \"Locality Name\"
send \"\\r\"
expect \"Organization Name\"
send \"\\r\"
expect \"Organizational Unit Name\"
send \"\\r\"
expect \"Common Name\"
send \"${EXASTRO_ITA_DOMAIN}\\r\"
expect \"Email Address\"
send \"\\r\"
expect \"A challenge password\"
send \"\\r\"
expect \"An optional company name\"
send \"\\r\"
interact"

openssl x509 -days 3650 -req -signkey /tmp/${PRIVATE_KEY_FILE} -extfile /tmp/san.txt < /tmp/${CSR_FILE} > /tmp/${CERTIFICATE_FILE}

rm -f /tmp/${CSR_FILE}
rm -f /tmp/san.txt

mv /tmp/${PRIVATE_KEY_FILE} /etc/pki/tls/certs/
mv /tmp/${CERTIFICATE_FILE} /etc/pki/tls/certs/

cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc_httpd_conf.d/vhosts_exastro-it-automation.conf /etc/httpd/conf.d/

declare -A REPLACE_CHAR;
REPLACE_CHAR=(
    ["ita_directory"]="%%%%%ITA_DIRECTORY%%%%%"
    ["ita_domain"]="%%%%%ITA_DOMAIN%%%%%"
    ["certificate"]="%%%%%CERTIFICATE_FILE%%%%%"
    ["private_key"]="%%%%%PRIVATE_KEY_FILE%%%%%"
)

sed -i -e "s:${REPLACE_CHAR["ita_directory"]}:${EXASTRO_ITA_INSTALL_DIR}:g" /etc/httpd/conf.d/vhosts_exastro-it-automation.conf
sed -i -e "s:${REPLACE_CHAR["ita_domain"]}:${EXASTRO_ITA_DOMAIN}:g" /etc/httpd/conf.d/vhosts_exastro-it-automation.conf
sed -i -e "s:${REPLACE_CHAR["certificate"]}:${CERTIFICATE_FILE}:g" /etc/httpd/conf.d/vhosts_exastro-it-automation.conf
sed -i -e "s:${REPLACE_CHAR["private_key"]}:${PRIVATE_KEY_FILE}:g" /etc/httpd/conf.d/vhosts_exastro-it-automation.conf

systemctl restart httpd

#git_install
yum install -y git

