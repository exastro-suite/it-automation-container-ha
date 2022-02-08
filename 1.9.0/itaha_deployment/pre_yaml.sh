#!/bin/bash

#template_cp
\cp -pf itaha_all_template.yaml itaha_all.yaml

#nfs_server_ip
aft_pv_nfs_ip=

#default_setting
aft_ns_name=itaha01
aft_pv_db_path=\/exastro-database
aft_pv_file_path=\/exastro-file
aft_svc_cm_dbname=mariadb-np
aft_svc_webapp_nodeport=30080
aft_cm_ita_db_username=ita_db_user
aft_secret_ita_db_password=aXRhX2RiX3Bhc3N3b3Jk
aft_dep_ita_version=1.9.0
aft_dep_os=centos8
aft_dep_webapp_replicas=2
#aft_dep_webapp_terraform_ip=
#aft_dep_webapp_terraform_host=


sed -i s@\$\{bef_pv_nfs_ip\}@$aft_pv_nfs_ip@g itaha_all.yaml
sed -i s@\$\{bef_ns_name\}@$aft_ns_name@g itaha_all.yaml
sed -i s@\$\{bef_pv_db_path\}@$aft_pv_db_path@g itaha_all.yaml
sed -i s@\$\{bef_pv_file_path\}@$aft_pv_file_path@g itaha_all.yaml
sed -i s@\$\{bef_cm_dbname\}@$aft_svc_cm_dbname@g itaha_all.yaml
sed -i s@\$\{bef_svc_webapp_nodeport\}@$aft_svc_webapp_nodeport@g itaha_all.yaml
sed -i s@\$\{bef_cm_ita_db_username\}@$aft_cm_ita_db_username@g itaha_all.yaml
sed -i s@\$\{bef_secret_ita_db_password\}@$aft_secret_ita_db_password@g itaha_all.yaml
sed -i s@\$\{bef_dep_ita_version\}@$aft_dep_ita_version@g itaha_all.yaml
sed -i s@\$\{bef_dep_os\}@$aft_dep_os@g itaha_all.yaml
sed -i s@\$\{bef_dep_webapp_replicas\}@$aft_dep_webapp_replicas@g itaha_all.yaml
#sed -i s@\$\{bef_dep_webapp_terraform_host\}@$aft_dep_webapp_terraform_host@g itaha_all.yaml
#sed -i s@\$\{bef_dep_webapp_terraform_ip\}@$aft_dep_webapp_terraform_ip@g itaha_all.yaml
