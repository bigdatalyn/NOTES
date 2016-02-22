#!/bin/ksh

INT_SEC=3600
NUM_CYCLE=24
DATABASE="SAMPLE"

INT_MIN=$(expr ${INT_SEC} / 60)
CycCount=0

db2 connect to ${DATABASE}

while [[ ${CycCount} -le ${NUM_CYCLE} ]]
do

  db2 "call monreport.dbsummary(${INT_SEC})" >monreport.dbsummary.$(date "+%Y%m%d_%H%M%S").log
  db2 "call monreport.pkgcache(${INT_MIN})"  >monreport.pkgcache.$(date "+%Y%m%d_%H%M%S").log

  if [[ $? -gt 0 ]]
  then
      echo "MONREPORT procedure execution error occurred!"
      break
  fi

  CycCount=$(expr $CycCount + 1)
  
done


% db2 "select dbpartitionnum, substr(type,1,20) as type, substr(path,1,80) path from sysibmadm.dbpaths"

DBPARTITIONNUM TYPE                 PATH
-------------- -------------------- ----------------------------------------------------
             0 LOGPATH              /dbdata/actlog1/NODE0000/
             0 MIRRORLOGPATH        /dbdata/actlog2/NODE0000/
             0 DB_STORAGE_PATH      /dbdata/db2inst1/
             0 LOCAL_DB_DIRECTORY   /dbdata/db2inst1/db2inst1/NODE0000/sqldbdir/
             0 DBPATH               /dbdata/db2inst1/db2inst1/NODE0000/SQL00003/

  5 record(s) selected.
