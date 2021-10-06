#!/bin/bash -ex

##############################################################################
# Download Exastro IT Automation Installer

curl -SL ${EXASTRO_ITA_INSTALLER_URL} | tar -xzC ${EXASTRO_ITA_UNPACK_BASE_DIR}


##############################################################################
# Update all installed packages

dnf update -y


##############################################################################
# Build

yum install -y nfs-utils

sleep 60

mkdir -p /exastro/data_relay_storage/symphony
mkdir -p /exastro/data_relay_storage/conductor
mkdir -p /exastro/data_relay_storage/ansible_driver
mkdir -p /exastro/data_relay_storage/cobbler_driver
mkdir -p /exastro/ita_sessions
mkdir -p /exastro/ita-root/temp
mkdir -p /exastro/ita-root/uploadfiles
mkdir -p /exastro/ita-root/webroot/uploadfiles
mkdir -p /exastro/ita-root/webroot/menus/sheets
mkdir -p /exastro/ita-root/webroot/menus/users
mkdir -p /exastro/ita-root/webconfs/sheets
mkdir -p /exastro/ita-root/webconfs/users
mkdir -p /var/lib/mysql

cat << EOS > /etc/exports
/exastro/data_relay_storage/symphony  *(rw,no_root_squash)
/exastro/data_relay_storage/conductor  *(rw,no_root_squash)
/exastro/data_relay_storage/ansible_driver  *(rw,no_root_squash)
/exastro/data_relay_storage/cobbler_driver  *(rw,no_root_squash)
/exastro/ita_sessions  *(rw,no_root_squash)
/exastro/ita-root/temp  *(rw,no_root_squash)
/exastro/ita-root/uploadfiles  *(rw,no_root_squash)
/exastro/ita-root/webroot/uploadfiles  *(rw,no_root_squash)
/exastro/ita-root/webroot/menus/sheets  *(rw,no_root_squash)
/exastro/ita-root/webroot/menus/users  *(rw,no_root_squash)
/exastro/ita-root/webconfs/sheets  *(rw,no_root_squash)
/exastro/ita-root/webconfs/users  *(rw,no_root_squash)
/var/lib/mysql  *(rw,no_root_squash)
EOS


exportfs -ar

exportfs -v

systemctl start nfs-server

systemctl enable nfs-server

