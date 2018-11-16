#!/bin/sh
#Run from cron (crontab -l)
#1 0 * * * /home/figshare/figshare_gen_xml_from_ldap/cron.sh > /home/figshare/figshare_gen_xml_from_ldap/log/last_run.log 2>&1
#
RM="/bin/rm"
LOCKFILE="/home/figshare/bin/lockfile"
TMP_DIR="/tmp"
LOCK_PID_FILE=${TMP_DIR}/figshare_hr_feed.lock

${LOCKFILE} ${LOCK_PID_FILE} $$
if [ $? != 0 ] ; then  exit 0 ; fi


log_date=`date "+%Y-%m-%d"`
base_dir="/home/figshare/figshare_gen_xml_from_ldap"
${base_dir}/bin/run.rb > ${base_dir}/log/run_${log_date}.log 2>&1
#Upload commented out until we get the firewall open.
${base_dir}/bin/upload.py >> ${base_dir}/log/run_${log_date}.log 2>&1
#
/usr/bin/find ${base_dir}/log -mtime +30 -exec rm -f {} \;
/usr/bin/find ${base_dir}/user_xml_files -name figshare_hr_feed\*.xml -mtime +30 -exec rm -f {} \;

${RM} -f ${LOCK_PID_FILE}
