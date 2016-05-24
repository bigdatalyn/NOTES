cat /local/adm/bin/cron/reorgchk_stat.ksh
#!/usr/bin/ksh

. /local/adm/bin/maint/dir_def.conf

. /local/adm/bin/maint/cmd_def.conf

. /local/adm/bin/maint/common_function.ksh

MAILINGLIST=/local/adm/bin/maint/mailling_list

LOG_DIR=/dbhome/scriptlog/reorgchk
EXECUTION_LOG=$LOG_DIR/execution.log

################################################################################
# Main Start
################################################################################

#HACMP Check
if [[ -x $DIR_LBIN_MNT/servc_or_stdby ]]; then
   HACHECK=`$DIR_LBIN_MNT/servc_or_stdby`
else
   HACHECK=service
fi

if [[ $HACHECK = service ]]; then
    if [[ ! -d $LOG_DIR ]]; then
        $CMD_MKDIR $LOG_DIR
    fi
    $CMD_CHMOD 777 $LOG_DIR
    if [[ -f $EXECUTION_LOG || -s $EXECUTION_LOG ]]; then
        $CMD_CP /dev/null $EXECUTION_LOG
        # $CMD_CHMOD 755 $EXECUTION_LOG
    fi    

        DB2ILIST=`db2_instance_list`
        if [[ $? != 0 ]]; then
                print "Function 'db2_instatnce_list' terminated abnormally. \nPlease check $FUNC_LOG " | \
                mail -s "Server `uname -n`, Warning has been generated by `basename $0`" `cat $MAILINGLIST`
        fi
    for Instance_Name in $DB2ILIST;do
        if [[ ! -d $DIR_DBLG_DMP/$Instance_Name ]];then
            $CMD_MKDIR $DIR_DBLG_DMP/$Instance_Name
        fi
        $CMD_ECHO "***** Instance-Name:$Instance_Name" >> $EXECUTION_LOG
        $CMD_CHMOD 775 $EXECUTION_LOG
                $CMD_CHGRP db2sysa $EXECUTION_LOG
        su - $Instance_Name -c "LANG=en_US; $DIR_LBIN_CRN/reorgchk_fork.ksh"
    done
else
    $CMD_ECHO "This node is standby node cannot start!!"
fi

exit 0


cat /local/adm/bin/cron/reorgchk_fork.ksh
#!/bin/ksh

#--- read define file for AHE ---#
. /local/adm/bin/maint/ahe_dir_def.conf
. /local/adm/bin/maint/ahe_cmd_def.conf

#local settings

instance=`whoami`
. $HOME/.profile
export LANG=en_US

CODE_WORD="Database code page" 

LOG_DIR=/dbhome/scriptlog/reorgchk
EXECUTION_LOG=$LOG_DIR/execution.log

#get db list & connect db & execute reorgchk

$CMD_LSTDB | $CMD_GREP -p "Indirect" | $CMD_GREP "Database name"| $CMD_AWK '{print $4}' |while read DBname
do
  CODE_PAGE=`db2 get db cfg for $DBname| $CMD_GREP "$CODE_WORD"| sed 's/^.*= //'`
  case $CODE_PAGE in
    850 ) export LANG=en_US
    ;;
    932 ) export LANG=Ja_JP.IBM-932
    ;;
    943 ) export LANG=Ja_JP
    ;;
    950 ) export LANG=Zh_TW
    ;;
    970 ) export LANG=ko_KR
    ;;
    1208 ) export LANG=en_US
    ;;
    1383 ) export LANG=zh_CN
    ;;
    * )
    ;;
  esac
  db2 terminate
  $CMD_ECHO "***** DB-Name:$DBname" >> $EXECUTION_LOG
  db2 connect to $DBname
  db2 reorgchk current statistics on table all > $DIR_DBLG_DMP/$instance/$instance"_"$DBname"_"reorgchk.log.$CMD_DATE_Ymd
  if [[ $? = 0 ]];then
    $CMD_ECHO "***** complete reorgchk" >> $EXECUTION_LOG
    $CMD_CHMOD 755 $DIR_DBLG_DMP/$instance/$instance"_"$DBname"_"reorgchk.log.$CMD_DATE_Ymd
  else
    $CMD_ECHO "***** error! reorgchk" >> $EXECUTION_LOG
  fi
  db2 terminate
done


