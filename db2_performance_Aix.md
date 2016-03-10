#!/bin/ksh
#DB2 Service - Mike Cornish
#data collection script for general DB2 performance and hang issues on AIX
#
#******************WARNING*************WARNING****************
#  This script should be run only at the request of 
#  DB2 support.  It can cause significant performance
#  degradation, especially on busy systems with a
#  high number of active connections
#*************************************************************
#
#run as instance owner (assuming SYSADM authority), 
#   all data will be dumped to the current directory
#   This is NOT to be set up as a cron job.
#
# NOTE: elapsed time could be taken to be as high as 40 minutes, 
#       in many cases the time will be much less
#       in systems under extremely heavy load or experiencing hangs
#       from deadlatches, the script may hang.
#       In most cases, we will still have sufficient data to investigate.
#
# Data will be collected for the databases provided as arguments.
# Snapshot and DB2 configuration data will be collected for the default
#    logical node only unless $DB2SERVICENODES is set, in which case
#    snapshot data will be obtained for each node listed, eg.
#    export DB2SERVICENODES="1 3 5" 

if [ $# -eq 0 ] ; then
 echo "Usage: db2service.perf1 <database1> <database2> ..."
 exit
fi

echo ""
echo "*********WARNING*************WARNING****************"
echo "This script should be run only at the request of" 
echo "DB2 support.  It can cause significant performance"
echo "degradation, especially on busy systems with a"
echo "high number of active connections"
echo "****************************************************"
sleep 5
echo ""
echo "You have 10 seconds to cancel this script with Ctrl-C"
sleep 10

#Check for MLN
if test -z "$DB2SERVICENODES" ; then
 MLN=0
 DB2SERVICENODES="X"
else
 MLN=1
fi

mkdir OSCONFIG >> db2service.log 2>&1 
mkdir DB2CONFIG >> db2service.log 2>&1 
mkdir OSSNAPS >> db2service.log 2>&1 
mkdir DB2SNAPS >> db2service.log 2>&1 
mkdir OSTRACE >> db2service.log 2>&1 
mkdir DB2TRACE >> db2service.log 2>&1 
mkdir DB2PD >> db2service.log 2>&1

tarupfiles()
{
tar -cvf db2service.out.tar DB2CONFIG DB2SNAPS DB2TRACE OSCONFIG \
    OSSNAPS OSTRACE DB2PD db2service.* >> db2service.log 2>&1
if [ $? -eq 0 ] ; then
  echo "removing directories... "
  rm -Rf OSCONFIG DB2CONFIG OSSNAPS DB2SNAPS OSTRACE DB2TRACE DB2PD 
fi  
  datestamp=`date +"%m%d"`.`date +"%H%M"`
  mv db2service.out.tar db2service.$datestamp.tar
compress db2service.$datestamp.tar
echo "output files have been tarred and compressed into db2service.$datestamp.tar.Z" `date` | tee -a db2service.log
echo ""
echo "Please place this file into your Diagnostic directory"
echo "   DIAGPATH - <instance_home>/sqllib/db2dump by default"
echo "tar and compress the entire diagnostic directory into <Your PMR number>.tar.Z"
echo "NOTE: it may be necessary to add additional characters after <Your PMR number>"
echo "   for uniqueness when ftping the file to testcase"
echo ""
echo "Please ftp the file to testcase.boulder.ibm.com"
echo "Login as anonymous, password is your email address"
echo "Upload <Your PMR number>.tar.Z into /ps/toibm/db2 in binary format"
echo ""
echo "Please notify the service analyst handling the PMR once the file"
echo "  has been successfully uploaded"
echo "Thank you"
echo ""
}

trap "echo Please allow a few minutes for cleanup ; \
      tarupfiles; exit" 1 2

#ANNOUNCE
echo "If at anytime during the execution of this script, the duration"
echo "exceeds the maximum suggested time, issue Ctrl-C to cancel"
echo "The script will then clean up, dump any active db2 trace,"
echo "and tar up output files.  Please allow 3 minutes for this"
echo ""
echo ""
sleep 15


#OS CONFIG info
echo "started OS CONFIG info" `date` | tee -a db2service.log
echo "should complete in less than one minute" 
/usr/bin/oslevel -s > OSCONFIG/machine.cfg 2>&1
/usr/sbin/lsattr -E -l sys0 >> OSCONFIG/machine.cfg 2>&1
/usr/sbin/lsattr -El css0 >> OSCONFIG/machine.cfg 2>&1
/usr/sbin/lsdev -C >> OSCONFIG/machine.cfg 2>&1
no -a >> OSCONFIG/machine.cfg 2>&1
/usr/bin/lslpp -ah > OSCONFIG/lslpp.h 2>&1
errpt -a > OSCONFIG/errpt.txt 2>&1
echo "finished OS CONFIG info" `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#DB2 config 1 - these should always execute.
echo "starting basic DB2 CONFIG info"  `date` | tee -a db2service.log
echo "should complete in less than one minute"
db2set -all > DB2CONFIG/db2set.all 2>>db2service.log
db2level > DB2CONFIG/db2level.txt 2>>db2service.log
set > DB2CONFIG/set.txt 2>&1
cp $HOME/sqllib/db2nodes.cfg DB2CONFIG > /dev/null 2>&1
echo "finished basic DB2 CONFIG info"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#OS monitor info 1
echo "starting first iteration of OS monitor info"  `date` | tee -a db2service.log
echo "should complete in less than 2 minutes"
uptime > OSSNAPS/netstat.1 2>&1
netstat -v >> OSSNAPS/netstat.1 2>&1
netstat -s -f inet >> OSSNAPS/netstat.1 2>&1
netstat -m >> OSSNAPS/netstat.1 2>&1
uptime > OSSNAPS/nfsstat.1 2>&1
nfsstat >> OSSNAPS/nfsstat.1 2>&1
uptime > OSSNAPS/vmstat.1 2>&1
vmstat 1 10 >> OSSNAPS/vmstat.1 2>&1
uptime > OSSNAPS/iostat.1 2>&1
iostat 5 6 >> OSSNAPS/iostat.1 2>&1
uptime > OSSNAPS/pskelf.1 2>&1
ps -kelf | sort +5 -rn >> OSSNAPS/pskelf.1 2>&1
uptime > OSSNAPS/psaux.1 2>&1 
ps aux | sort +5 -rn >> OSSNAPS/psaux.1 2>&1
uptime > OSSNAPS/ipcs.1 2>&1 
ipcs -a >> OSSNAPS/ipcs.1 2>&1
uptime > OSSNAPS/lsps.1 2>&1
lsps -a >> OSSNAPS/lsps.1 2>&1
echo "finished first iteration of OS monitor info"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log
sleep 30

#OS monitor info 2
echo "starting second iteration of OS monitor info"  `date` | tee -a db2service.log
echo "should complete in less than 2 minutes"
uptime > OSSNAPS/netstat.2 2>&1
netstat -v >> OSSNAPS/netstat.2 2>&1
netstat -s -f inet >> OSSNAPS/netstat.2 2>&1
netstat -m >> OSSNAPS/netstat.2  2>&1
uptime > OSSNAPS/nfsstat.2 2>&1
nfsstat >> OSSNAPS/nfsstat.2 2>&1
uptime > OSSNAPS/vmstat.2 2>&1
vmstat 1 10 >> OSSNAPS/vmstat.2 2>&1
uptime > OSSNAPS/iostat.2 2>&1
iostat 5 6 >> OSSNAPS/iostat.2 2>&1
uptime > OSSNAPS/pskelf.2 2>&1
ps -kelf |sort +5 -rn >> OSSNAPS/pskelf.2 2>&1
uptime > OSSNAPS/psaux.2 2>&1 
ps aux | sort +5 -rn >> OSSNAPS/psaux.2 2>&1
uptime > OSSNAPS/ipcs.2 2>&1
ipcs -a >> OSSNAPS/ipcs.2 2>&1
uptime > OSSNAPS/lsps.2 2>&1
lsps -a >> OSSNAPS/lsps.2 2>&1
echo "finished second iteration of OS monitor info"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#partial call stacks
echo "taking call stacks of top CPU agents"  `date` | tee -a db2service.log
echo "should complete in less than 6 minutes"
ps -elf | sort +5 -rn | egrep "db2ag|db2pfchr|db2pclnr" | grep $DB2INSTANCE | grep -v grep | head -20 > DB2SNAPS/top.db2agents.1 2>> db2service.log
kill -36 `awk '{print $4}' DB2SNAPS/top.db2agents.1` >> db2service.log 2>&1
sleep 120
ps -elf | sort +5 -rn | egrep "db2ag|db2pfchr|db2pclnr" | grep $DB2INSTANCE | grep -v grep | head -20 > DB2SNAPS/top.db2agents.2 2>> db2service.log
kill -36 `awk '{print $4}' DB2SNAPS/top.db2agents.2` >> db2service.log 2>&1
sleep 120
echo "finished call stacks"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#AIX trace
echo "starting AIX trace" `date` | tee -a db2service.log
echo "should complete in less than 3 minutes"  
trace -L 8000000 -ao ./OSTRACE/aixtrace.raw >> db2service.log 2>&1
sleep 30
trcstop >> db2service.log 2>&1
echo "formatting AIX trace" `date` | tee -a db2service.log
trcrpt -O exec=on,pid=on ./OSTRACE/aixtrace.raw > ./OSTRACE/aixtrace.fmt
echo "finished AIX trace"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#db2 trace
#issue trace initialization signal *only* if db2fmp32 doesn't exist .
echo "starting db2 trace"  `date` | tee -a db2service.log
echo "Issue Ctrl-C if not completed within 3 minutes"
db2trc on -l 8388608 -t >> db2service.log 2>&1
ps -elf | grep -v grep | grep db2fmp32 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "No db2fmp32 processes, issued trace init signal" | tee -a db2service.log

  #Please Note that the '-' below is required.  It sends the signal to the
  #entire db2sysc process group , i.e. -(process_ID_of_db2sysc>
  #processes such as db2ckpwd are in the process group but run as root .
  #this results in a return such as "kill: -273198: Permission denied."
  #though the command will have been as successful (as possible), i.e. we
  #will have sent the signal to all the processes we have access to.

  kill -60 `ps -elf|grep $DB2INSTANCE|grep db2sysc|grep -v grep| awk '{print '-'$4}'`
else 
  echo "db2fmp32 processes exist, couldn't issue trace init signal" | tee -a db2service.log
fi
sleep 30
db2trc dmp DB2TRACE/db2trace1.raw >> db2service.log 2>&1
db2trc off >> db2service.log 2>&1
echo "formatting trace" `date` | tee -a db2service.log
db2trc flw DB2TRACE/db2trace1.raw DB2TRACE/db2trace1.flw >> db2service.log 2>&1
db2trc fmt DB2TRACE/db2trace1.raw DB2TRACE/db2trace1.fmt >> db2service.log 2>&1
sleep 30
echo "db2 trace complete"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#full call stacks
echo "taking full call stacks"  `date` | tee -a db2service.log
echo "Issue Ctrl-C if not completed within 10 minutes"

  #Please Note that the '-' below is required.  It sends the signal to the
  #entire db2sysc process group , i.e. -(process_ID_of_db2sysc>
  #processes such as db2ckpwd are in the process group but run as root .
  #this results in a return such as "kill: -273198: Permission denied."
  #though the command will have been as successful (as possible), i.e. we
  #will have sent the signal to all the processes we have access to.

kill -36 `ps -elf|grep $DB2INSTANCE|grep db2sysc|grep -v grep| awk '{print '-'$4}'`
sleep 300
uptime > OSSNAPS/pself.3 2>&1
ps -elf |sort +5 -rn >> OSSNAPS/pself.3 2>&1
echo "finished taking full call stacks"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#DB2PD info - more to be gathered later
echo "gathering db2pd info" `date` | tee -a db2service.log
echo "should complete in less than 3 minutes"
db2pd -inst -alldbs > DB2PD/db2pd.inst.alldbs 2>&1
db2pd -inst -alldbs -alldbp -mempools > DB2PD/db2pd.mem 2>&1
#DB2 config 2 - issuing this late in case any of these hang.
echo "gathering more DB2 CONFIG info"  `date` | tee -a db2service.log
echo "Issue Ctrl-C if not completed within 5 minutes"

#grabbing a quick second trace here 
`db2trc on -l 8388608 -t >> db2service.log 2>&1
 sleep 2
 db2trc dmp DB2TRACE/db2trace2.raw >> db2service.log 2>&1
 db2trc off >> db2service.log 2>&1
 db2trc flw DB2TRACE/db2trace2.raw DB2TRACE/db2trace2.flw >> db2service.log 2>&1
 db2trc fmt DB2TRACE/db2trace2.raw DB2TRACE/db2trace2.fmt >> db2service.log 2>&1
 `&
db2 get dbm cfg > DB2CONFIG/dbm.cfg 2>&1
db2 terminate >> db2service.log 2>&1

for NODE in $DB2SERVICENODES
do
 if [ $MLN -eq 1 ] ; then
  export DB2NODE=$NODE
 fi
 for DB in $*
 do
  db2 connect to $DB  >> db2service.log 2>&1
  db2 "select * from syscat.bufferpools" > DB2CONFIG/$DB.bpcfg.n$NODE 2>&1
  db2 get db cfg for $DB > DB2CONFIG/$DB.dbcfg.n$NODE 2>&1
  db2 terminate >> db2service.log 2>&1
 done
done
echo "finished gathering more DB2 CONFIG info"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

#DB2 monitoring info - issuing this later in case of monitor latch contention
echo "gathering DB2 monitoring info"  `date` | tee -a db2service.log
echo "Issue Ctrl-C if not completed within 10 minutes"

for NODE in $DB2SERVICENODES
do
 if [ $MLN -eq 1 ] ; then
  export DB2NODE=$NODE
  db2 terminate >> db2service.log 2>&1
 fi
 db2 update monitor switches using bufferpool on lock on sort on statement on table on uow on >> db2service.log 2>&1
 db2pd -inst -alldbs > DB2PD/db2pd.inst.alldbs.$NODE.1 2>&1
 db2 get snapshot for database manager > DB2SNAPS/dbmsnap.n$NODE.1 2>&1
 db2 list applications show detail > DB2SNAPS/listapps.n$NODE.1 2>&1
 for DB in $*
 do
  db2 get snapshot for database on $DB > DB2SNAPS/$DB.dbsnap.n$NODE.1 2>&1
  db2 get snapshot for applications on $DB > DB2SNAPS/$DB.appsnap.n$NODE.1 2>&1
  db2 get snapshot for tables on $DB > DB2SNAPS/$DB.tablesnap.n$NODE.1 2>&1
  db2 get snapshot for tablespaces on $DB > DB2SNAPS/$DB.tbspsnap.n$NODE.1 2>&1
  db2 get snapshot for locks on $DB > DB2SNAPS/$DB.locksnap.n$NODE.1 2>&1
  db2 get snapshot for bufferpools on $DB > DB2SNAPS/$DB.bpsnap.n$NODE.1 2>&1
 done
done
sleep 60
for NODE in $DB2SERVICENODES
do
 if [ $MLN -eq 1 ] ; then
  export DB2NODE=$NODE
  db2 terminate >> db2service.log 2>&1
  db2 update monitor switches using bufferpool on lock on sort on statement on table on uow on >> db2service.log 2>&1
 fi
 db2pd -inst -alldbs > DB2PD/db2pd.inst.alldbs.$NODE.2 2>&1
 db2 get snapshot for database manager > DB2SNAPS/dbmsnap.n$NODE.2 2>&1
 db2 list applications show detail > DB2SNAPS/listapps.n$NODE.2 2>&1
 for DB in $*
 do
  db2 get snapshot for database on $DB > DB2SNAPS/$DB.dbsnap.n$NODE.2 2>&1
  db2 get snapshot for applications on $DB > DB2SNAPS/$DB.appsnap.n$NODE.2 2>&1
  db2 get snapshot for tables on $DB > DB2SNAPS/$DB.tablesnap.n$NODE.2 2>&1
  db2 get snapshot for tablespaces on $DB > DB2SNAPS/$DB.tbspsnap.n$NODE.2 2>&1
  db2 get snapshot for locks on $DB > DB2SNAPS/$DB.locksnap.n$NODE.2 2>&1
  db2 get snapshot for bufferpools on $DB > DB2SNAPS/$DB.bpsnap.n$NODE.2 2>&1
  db2 get snapshot for dynamic sql on $DB > DB2SNAPS/$DB.n$NODE.dynsnap 2>&1
 done
done
echo "finished gathering DB2 monitoring info"  `date` | tee -a db2service.log
echo ""| tee -a db2service.log

tarupfiles
