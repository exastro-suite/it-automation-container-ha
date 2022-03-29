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
# DNF repository (ubi8)

cat << 'EOS' > /etc/yum.repos.d/centos8.repo
[baseos]
name=AlmaLinux $releasever - BaseOS
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos
# baseurl=https://repo.almalinux.org/almalinux/$releasever/BaseOS/$basearch/os/
gpgcheck=0
enabled=0
[appstream]
name=AlmaLinux $releasever - AppStream
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream
# baseurl=https://repo.almalinux.org/almalinux/$releasever/AppStream/$basearch/os/
gpgcheck=0
enabled=0
EOS


##############################################################################
# dnf and repository configuration (ubi8)
dnf install -y dnf-plugins-core
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf config-manager --disable epel epel-modular


##############################################################################
# install common packages (installer requirements) (ubi8)

dnf install -y diffutils procps which openssl
dnf install -y --enablerepo=baseos expect


##############################################################################
# install required packages (ubi8)

dnf install -y rsyslog  # for writing /var/log/messages
dnf install -y hostname
dnf install -y --enablerepo=appstream telnet


##############################################################################
# install ansible related packages (ubi8)

dnf install -y --enablerepo=epel sshpass


##############################################################################
# install MariaDB related packages (ubi8)
#   see https://mariadb.com/ja/resources/blog/how-to-install-mariadb-on-rhel8-centos8/
#   note: MariaDB 10.6 requires libpmem

dnf install -y perl-DBI libaio libsepol lsof
dnf install -y rsync iproute # additional installation
dnf install -y --enablerepo=appstream boost-program-options libpmem


##############################################################################
# Set system locale and system timezone
dnf install -y glibc-locale-source
/usr/bin/localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localectl set-locale LANG=ja_JP.UTF-8
timedatectl set-timezone Asia/Tokyo


##############################################################################
# ExcelExport JapaneseLanguage GarbledCharacters (container only)
dnf -y --enablerepo=appstream reinstall langpacks-en


##############################################################################
# Python interpreter warning issue (container only)
#   see https://docs.ansible.com/ansible/2.10/reference_appendices/interpreter_discovery.html

find ${EXASTRO_ITA_UNPACK_BASE_DIR} | grep -E "/ansible.cfg$" | xargs sed -i -E 's/^\[defaults\]$/[defaults\]\ninterpreter_python=auto_silent/'

#sizai_deploy
cd ${EXASTRO_ITA_UNPACK_BASE_DIR}
find it-automation-${EXASTRO_ITA_VER} -type f | xargs -I{} sed -i -e "s:%%%%%ITA_DIRECTORY%%%%%:${EXASTRO_ITA_INSTALL_DIR}:g" {}

mkdir -p /exastro-database-volume/mysql
ln -s /exastro-database-volume/mysql /var/lib/mysql

#mariadb_install
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
yum clean all
yum install -y mariadb mariadb-server

systemctl enable mariadb
systemctl start mariadb

#create dbuser
cat << EOS > /tmp/create-db-and-user_for_MySQL.sql
CREATE USER 'ITA_USER' IDENTIFIED BY 'ITA_PASSWD';
CREATE USER 'ITA_USER'@'localhost' IDENTIFIED BY 'ITA_PASSWD';
CREATE DATABASE ITA_DB CHARACTER SET utf8;
GRANT ALL ON ITA_DB.* TO 'ITA_USER'@'%' WITH GRANT OPTION;
GRANT ALL ON ITA_DB.* TO 'ITA_USER'@'localhost' WITH GRANT OPTION;
EOS

sed -i -e "s/ITA_DB/${EXASTRO_ITA_DB_NAME}/g" /tmp/create-db-and-user_for_MySQL.sql
sed -i -e "s/ITA_USER/${EXASTRO_ITA_DB_USERNAME}/g" /tmp/create-db-and-user_for_MySQL.sql
sed -i -e "s/ITA_PASSWD/${EXASTRO_ITA_DB_PASSWORD}/g" /tmp/create-db-and-user_for_MySQL.sql
mysql -uroot < /tmp/create-db-and-user_for_MySQL.sql

rm -f /tmp/create-db-and-user_for_MySQL.sql

# MariaDB (initialize)
send_db_root_password="${EXASTRO_ITA_DB_ROOT_PASSWORD}"
send_db_root_password=$(echo "$send_db_root_password"|sed -e 's/\\/\\\\\\\\/g')
send_db_root_password=$(echo "$send_db_root_password"|sed -e 's/\$/\\\\\\$/g')
send_db_root_password=$(echo "$send_db_root_password"|sed -e 's/"/\\\\\\"/g')
send_db_root_password=$(echo "$send_db_root_password"|sed -e 's/\[/\\\\\\[/g')
send_db_root_password=$(echo "$send_db_root_password"|sed -e 's/\t/\\011/g')

#mysql_secure_installation
expect -c "
    set timeout -1
    spawn mysql_secure_installation
    expect \"Enter current password for root \\(enter for none\\):\"
    send \"\\r\"
    expect {
        -re \"Switch to unix_socket authentication.* $\" {
            send \"n\\r\"
            expect -re \"Change the root password\\?.* $\"
            send \"Y\\r\"
        }
        -re \"Set root password\\?.* $\" {
            send \"Y\\r\"
        }
    }
    expect \"New password:\"
    send \""${send_db_root_password}\\r"\"
    expect \"Re-enter new password:\"
    send \""${send_db_root_password}\\r"\"
    expect -re \"Remove anonymous users\\?.* $\"
    send \"Y\\r\"
    expect -re \"Disallow root login remotely\\?.* $\"
    send \"Y\\r\"
    expect -re \"Remove test database and access to it\\?.* $\"
    send \"Y\\r\"
    expect -re \"Reload privilege tables now\\?.* $\"
    send \"Y\\r\""

#copy server.cnf
cp -p ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ext_files_for_CentOS8.x/etc_my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf
systemctl restart mariadb

#create table
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-a.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-c.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-d.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-m.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-m2.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-m3.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-n.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-p.sql
mysql -u ${EXASTRO_ITA_DB_USERNAME} -p${EXASTRO_ITA_DB_PASSWORD} -D ${EXASTRO_ITA_DB_NAME} < ${EXASTRO_ITA_UNPACK_BASE_DIR}/it-automation-${EXASTRO_ITA_VER}/ita_install_package/ITA/ita-sqlscripts/ja_JP_mysql_ita_model-o.sql
