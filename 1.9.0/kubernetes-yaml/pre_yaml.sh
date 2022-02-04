#!/bin/bash

#template_cp
\cp -pf 99_itaha_all_template.yaml 99_itaha_all.yaml

#nfs_server_ip
aft_pv_nfs_ip=xxx.xxx.xxx.xxx

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


sed -i s@\$\{bef_pv_nfs_ip\}@$aft_pv_nfs_ip@g 99_itaha_all.yaml
sed -i s@\$\{bef_ns_name\}@$aft_ns_name@g 99_itaha_all.yaml
sed -i s@\$\{bef_pv_db_path\}@$aft_pv_db_path@g 99_itaha_all.yaml
sed -i s@\$\{bef_pv_file_path\}@$aft_pv_file_path@g 99_itaha_all.yaml
sed -i s@\$\{bef_cm_dbname\}@$aft_svc_cm_dbname@g 99_itaha_all.yaml
sed -i s@\$\{bef_svc_webapp_nodeport\}@$aft_svc_webapp_nodeport@g 99_itaha_all.yaml
sed -i s@\$\{bef_cm_ita_db_username\}@$aft_cm_ita_db_username@g 99_itaha_all.yaml
sed -i s@\$\{bef_secret_ita_db_password\}@$aft_secret_ita_db_password@g 99_itaha_all.yaml
sed -i s@\$\{bef_dep_ita_version\}@$aft_dep_ita_version@g 99_itaha_all.yaml
sed -i s@\$\{bef_dep_os\}@$aft_dep_os@g 99_itaha_all.yaml
sed -i s@\$\{bef_dep_webapp_replicas\}@$aft_dep_webapp_replicas@g 99_itaha_all.yaml
