1.transaction log full

  db2diag -lastrecords 500  | grep -i SQL0964C


recommended to filter out keywords using sqlcode ”SQL0964C” for determine the transaction log full issue  then clutch out the corresponding application handle by sqlcode “ADM1823E” 

2.

  db2 "update monitor switches using BUFFERPOOL on LOCK on sort on STATEMENT on TABLE on TIMESTAMP on UOW on"

vi trans_list.sql

  select integer(sdb.appl_id_oldest_xact) as "Oldest Transaction",
  integer(sa.uow_log_space_used /1024 / 1024)as "Log used(Mb)",
  integer(sa.locks_held) as "Locks Held",
  integer(sa.appl_idle_time) as "Idle (seconds)",
  time(sa.uow_stop_time) as "UOW Stop Time",
  sa.rows_selected as "Rows Selected",
  sa.rows_read as "Rows Read",
  integer(sa.rows_inserted) as "Rows Inserted",
  integer(sa.rows_updated) as "Rows Updated",
  integer(sa.rows_deleted) as "Rows Deleted"
  from
  sysibmadm.snapdb sdb
  inner join
  sysibmadm.snapappl sa
  on sa.db_name = sdb.db_name
  and sa.dbpartitionnum = sdb.dbpartitionnum
  and sa.agent_id = sdb.appl_id_oldest_xact
  ;  

chmod a+x trans_list.sql

  db2 connect to XXXX
  db2 -tvf trans_list.sql


3.

db2 get db cfg for db XXX | egrep "(LOGFILSIZ)|(LOGPRIMARY)|(LOGSECOND)"


4.

db2 "update monitor switches using BUFFERPOOL on LOCK on sort on STATEMENT on TABLE on TIMESTAMP on UOW off"



