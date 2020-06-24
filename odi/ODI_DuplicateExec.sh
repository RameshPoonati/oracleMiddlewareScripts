#!/bin/bash
source $HOME/scripts/ODIPRD.env
RETVAL=`sqlplus -silent system/Welcome123 <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select count(1) from 
  (select to_char(sess_beg, 'YYYY-MM-DD HH24:MI') , count(1)
    from WORKREPSSOP.snp_session
    where sess_name = 'ScenarioName'
    and sess_beg > sysdate - interval '30' minute
    group by to_char(sess_beg, 'YYYY-MM-DD HH24:MI')
    having count(1) > 1
    order by to_char(sess_beg, 'YYYY-MM-DD HH24:MI') desc
  );
EXIT;
EOF`
if [ $RETVAL -gt 0 ]; then
	echo "TO: emailids" > $HOME/scripts/ODI/ODI_DuplicateExec.html
	echo "Subject: Alert: Action Required - Multiple Executions of ODI Scenarios Observed" >> $HOME/scripts/ODI/ODI_DuplicateExec.html
	echo "MIME-Version: 1.0" >> $HOME/scripts/ODI/ODI_DuplicateExec.html
	cp $HOME/scripts/ODI/ODI_DuplicateExec.static $HOME/scripts/ODI/ODI_DuplicateExec.static_tmp
	sed -i "s/#V_COUNT#/$RETVAL/g" $HOME/scripts/ODI/ODI_DuplicateExec.static_tmp
	cat $HOME/scripts/ODI/ODI_DuplicateExec.static_tmp >> $HOME/scripts/ODI/ODI_DuplicateExec.html
	rm $HOME/scripts/ODI/ODI_DuplicateExec.static_tmp
	cat $HOME/scripts/ODI/ODI_DuplicateExec.html | /usr/sbin/sendmail -t
fi
