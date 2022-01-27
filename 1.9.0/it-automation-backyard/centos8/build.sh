#!/bin/bash -ex

##############################################################################
# Download Exastro IT Automation Installer

curl -SL ${EXASTRO_ITA_INSTALLER_URL} | tar -xzC ${EXASTRO_ITA_UNPACK_BASE_DIR}

##############################################################################
# Update all installed packages

dnf update -y


##############################################################################
# Build
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

#mariadb_install
yum install -y mariadb

#php_install
yum install -y yum-utils
yum install -y epel-release
yum config-manager --set-enabled powertools

yum install -y php php-bcmath php-cli php-ldap php-mbstring php-mysqlnd php-pear php-pecl-zip php-process php-snmp php-xml zip telnet mailx unzip php-json php-gd python3 php-devel libyaml libyaml-devel make sudo crontabs

pear install HTML_AJAX-beta

ln -s /usr/share/pear-data/HTML_AJAX/js /usr/share/pear/HTML/js

pecl channel-update pecl.php.net

echo "" | pecl install YAML

mkdir -p /usr/share/php/vendor

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin

/usr/bin/composer.phar require "phpoffice/phpspreadsheet":"1.14.1"

mv -f vendor /usr/share/php/

#php_setting
\cp -pf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc/php.ini /etc/
\cp -pf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc_php-fpm.d/www.conf /etc/php-fpm.d/

#ita_install
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/menus
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webconfs
mkdir -p ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs

mkdir -p /exastro-file-volume/data_relay_storage/ansible_driver
mkdir -p /exastro-file-volume/data_relay_storage/conductor
mkdir -p /exastro-file-volume/data_relay_storage/symphony
#mkdir -p /exastro-file-volume/ita-root/temp
#mkdir -p /exastro-file-volume/ita-root/uploadfiles
mkdir -p /exastro-file-volume/ita-root/webroot/menus/sheets
mkdir -p /exastro-file-volume/ita-root/webroot/menus/users
mkdir -p /exastro-file-volume/ita-root/webconfs/sheets
mkdir -p /exastro-file-volume/ita-root/webconfs/users
mkdir -p /exastro-file-volume/ita-root/confs


\cp -rpf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-contents/ita-root/* ${EXASTRO_ITA_INSTALL_DIR}/ita-root
\cp -rpf ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-confs/* ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs

#mount_point
ln -s /exastro-file-volume/data_relay_storage/ansible_driver ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/ansible_driver
ln -s /exastro-file-volume/data_relay_storage/conductor ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/conductor
ln -s /exastro-file-volume/data_relay_storage/symphony ${EXASTRO_ITA_INSTALL_DIR}/data_relay_storage/symphony

#ln -s /exastro-file-volume/ita-root/temp ${EXASTRO_ITA_INSTALL_DIR}/ita-root/temp
#ln -s /exastro-file-volume/ita-root/uploadfiles ${EXASTRO_ITA_INSTALL_DIR}/ita-root/uploadfiles
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


mv ${EXASTRO_ITA_INSTALL_DIR}/ita-root/temp /exastro-file-volume/ita-root
mv ${EXASTRO_ITA_INSTALL_DIR}/ita-root/uploadfiles /exastro-file-volume/ita-root
mv ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/uploadfiles /exastro-file-volume/ita-root/webroot

ln -s /exastro-file-volume/ita-root/temp ${EXASTRO_ITA_INSTALL_DIR}/ita-root/temp
ln -s /exastro-file-volume/ita-root/uploadfiles ${EXASTRO_ITA_INSTALL_DIR}/ita-root/uploadfiles
ln -s /exastro-file-volume/ita-root/webroot/uploadfiles ${EXASTRO_ITA_INSTALL_DIR}/ita-root/webroot/uploadfiles


cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_base ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_createparam ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_hostgroup ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_ansible-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_cobbler-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-releasefiles/ita_terraform-driver ${EXASTRO_ITA_INSTALL_DIR}/ita-root/libs/release/.

#db_connect_setting
echo -ne "mysql:dbname=ita_db;host=${EXASTRO_ITA_DB_SERVICE_NAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_connection_string.txt

echo -ne "${EXASTRO_ITA_DB_USERNAME}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_username.txt

echo -ne "${EXASTRO_ITA_DB_PASSWORD}" | base64 | tr '[A-Za-z]' '[N-ZA-Mn-za-m]' > ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/commonconfs/db_password.txt

#backyard_setting
ln -s ${EXASTRO_ITA_INSTALL_DIR}/ita-root/confs/backyardconfs/ita_env /etc/sysconfig/ita_env

#service_base_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/base_service_list.txt

#service_createparam_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/createparam_service_list.txt

#service_hostgroup_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/hostgroup_service_list.txt

#service_ansible_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/ansible_service_list.txt

#service_createparam2_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/createparam2_service_list.txt

#service_cobbler_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/cobbler_service_list.txt

#service_terraform_service_list.txt
while read line
do
  cp -p ${EXASTRO_ITA_INSTALL_DIR}${line}.service /usr/lib/systemd/system/.
done < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/install_scripts/list/terraform_service_list.txt

ls -1 /usr/lib/systemd/system/. | grep ky_ | xargs systemctl enable
ls -1 /usr/lib/systemd/system/. | grep ky_ | xargs systemctl start

#cron_setting
cat << EOS > /var/spool/cron/root
01 00 * * * su - -c ${EXASTRO_ITA_INSTALL_DIR}/ita-root/backyards/common/ky_execinstance_dataautoclean-workflow.sh'
02 00 * * * su - -c ${EXASTRO_ITA_INSTALL_DIR}/ita-root/backyards/common/ky_file_autoclean-workflow.sh'
EOS

#git_install
yum install -y git
