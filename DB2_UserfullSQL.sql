1.查看表空情况和大小

1.1.使用一条命令即可查看表空间的状态信息，格式化输出 db2 list tablespaces show detail 

LANG=en_US;db2 terminate; db2 connect to SAMPLE;

db2 list tablespaces show detail | while read line  ; do w1=$(echo "$line" | cut -d" " -f1); if [ "$w1" ==  "Tablespace" ];then tabid=$(echo "$line" | cut -d'=' -f2);fi; if [ "$w1" ==  "Name" ];then   name=$(echo "$line" | cut -d'=' -f2); fi; if [ "$w1" ==  "Type" ];then  type=$(echo "$line" | cut -d'=' -f2);type1=$(echo "$type" | awk '{print $1}'); if [ "$type1" == "System" ];then Ttype='SMS';  else Ttype='DMS'; fi;  fi; if [ "$w1" == "Contents" ];then contents=$(echo "$line" | cut -d'=' -f2); fi; if  [ "$w1" ==  "State" ];then state=$(echo "$line" | cut -d'=' -f2);fi; if [ "$w1" == "Total" ];then   total=$(echo "$line" | cut -d'=' -f2);fi;if [ "$w1" == "Used" ]; then used=$(echo "$line" | cut -d'=' -f2); fi;  if [ "$w1" ==  "Free" ]; then free=$(echo "$line" | cut -d'=' -f2); fi; if [ "$w1" == "Page" ];then page=$(echo "$line" | cut -d'=' -f2); printf "%-25s%-5s%-5s%-5s%-10s%-20s%-20s%-30s\n"  $name $tabid $page $Ttype $state $total $used; fi  done

SAMPLE:数据库名

我们有时候需要查看表空间状态，方式有很多，db2pd, db2 list, 当表空间较多的情况下，往往信息太多，导致不是很方便的查看信息。对于db2pd 方便之处在于不用连接数据库，即可以查询表空间信息，并且对表空间信息进行了较全的输出；db2 list,可以以表空间为单位输出对应表空间的信息；但是这两种方式对于表空间较多的数据库来说用起来很不方便。 

1.2.通过视图查看表空间信息，包括表空间状态，总page数，可使用的page数，使用的page数，空闲的page数，是否自动扩展 

db2 "select  substr(TBSP_NAME,1,20) as TBSPNAME, 
TBSP_TYPE, 
substr(TBSP_STATE,1,10) as TBSPSTATE , 
substr(TBSP_TOTAL_PAGES,1,10) as TOTAL_PAGES, 
substr(TBSP_USABLE_PAGES,1,10) as USABLE_PAGES, 
substr(TBSP_USED_PAGES,1,5) as USED_PAGES, 
substr(TBSP_FREE_PAGES,1,5) as FREE_PAGES, 
substr(TBSP_MAX_SIZE,1,5) as MAX_SIZE, 
substr(TBSP_USING_AUTO_STORAGE,1,2) as AUTOStr, 
substr(TBSP_AUTO_RESIZE_ENABLED,1,2)  as AUTORes from SYSIBMADM.TBSP_UTILIZATION"


2.查看当前数据库名

db2 "select current server from sysibm.sysdummy1"

3.通过存储过程查看数据库大小，单位byte

db2 "CALL GET_DBSIZE_INFO(?, ?, ?, 0) "

4.表空间自动扩展设置

4.1.查看表空间是否为自动扩展 

db2 "select substr(TBSP_NAME,1,30) as DMS_tablespace_without_autoresize, TBSP_USING_AUTO_STORAGE, TBSP_AUTO_RESIZE_ENABLED from SYSIBMADM.TBSP_UTILIZATION where TBSP_TYPE='DMS' and TBSP_AUTO_RESIZE_ENABLED=0"

4.2.生成修改表空间为自动扩展 

db2 -x "select 'ALTER TABLESPACE '|| TBSP_NAME ||' AUTORESIZE YES;'  from SYSIBMADM.TBSP_UTILIZATION where TBSP_TYPE='DMS' and TBSP_AUTO_RESIZE_ENABLED=0"

step 1: 

db2 -x "select 'ALTER TABLESPACE '|| TBSP_NAME ||' AUTORESIZE YES;'  from SYSIBMADM.TBSP_UTILIZATION where TBSP_TYPE='DMS' and TBSP_AUTO_RESIZE_ENABLED=0"  | tee changeTBSauto.sql 
step 2: 

db2 -tvf changeTBSauto.sql

5.扩表空间步骤

查看表空间使用率

db2 "select TBSP_ID,substr(TBSP_NAME,1,30) as TBSP_NAME, TBSP_TYPE, TBSP_TOTAL_SIZE_KB/1024 as TOTAL_M,TBSP_USED_SIZE_KB/1024 as USED_M,TBSP_UTILIZATION_PERCENT as Pct, TBSP_USING_AUTO_STORAGE, TBSP_AUTO_RESIZE_ENABLED from SYSIBMADM.TBSP_UTILIZATION" |grep CLOBS_TSP

查看表空间属性（是否自动扩展，看AR/auto resize字段）

db2pd -db PMOR11 -tablespace 5

查看扩展到目标使用率需要扩展多少容量

db2 "select substr(TBSP_NAME,1,30) as TBSP_NAME,round((TBSP_USED_SIZE_KB/1024/0.75),0) as After_Extend_M,TBSP_USED_SIZE_KB/1024/0.75-TBSP_TOTAL_SIZE_KB/1024 Should_Extend_M from SYSIBMADM.TBSP_UTILIZATION where TBSP_NAME='CLOBS_TSP'"

查看目标服务器是否为高可用架构

db2pd -db CWAMAPP -hadr

查看是否有备份恢复task正在执行中

db2 list utilities show detail

扩展表空间

alter tablespace CLOBS_TSP extend (all 30M)

6.查看表大小

db2 "SELECT SUBSTR(TabSchema,1,15), TabName, TabType, (Data_Object_P_Size + Index_Object_P_Size + Long_Object_P_Size + Lob_Object_P_Size + Xml_Object_P_Size)/1024 as Total_P_Size_MB FROM SysIbmAdm.AdminTabInfo ORDER BY Total_P_Size_MB desc" >table_size.log

http://db2commerce.com/2015/02/05/db2-administrative-sql-cookbook-listing-tables-and-current-size/

v10.5

select  substr(t.tabschema,1,18) as tabschema
        , substr(t.tabname,1,40) as tabname
        , (COL_OBJECT_P_SIZE + DATA_OBJECT_P_SIZE + INDEX_OBJECT_P_SIZE + LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE)/1024 as tab_size_mb
        , tableorg
from    syscat.tables t
        join sysibmadm.admintabinfo ati
                on t.tabname=ati.tabname
                and t.tabschema=ati.tabschema
where   t.type='T'
        and t.tabschema not like ('SYS%')
order by 3 desc
with ur

v9.7

select  substr(t.tabschema,1,18) as tabschema
        , substr(t.tabname,1,40) as tabname
        , (DATA_OBJECT_P_SIZE + INDEX_OBJECT_P_SIZE)/1024 as tab_size_mb
from    syscat.tables t
        join sysibmadm.admintabinfo ati
                on t.tabname=ati.tabname
                and t.tabschema=ati.tabschema
where   t.type='T'
        and t.tabschema not like ('SYS%')
order by 3 desc
with ur



7.查询存储过程的内容

db2 " select PROCNAME,text from syscat.procedures where PROCNAME = 'SP_A_TSKRES'"

8.检查数据库中是否有对象状态处于完整性检查，并生成执行语句

db2 connect to sample
db2 -tx +w "with gen(tabname, seq) as( select rtrim(tabschema) || '.' || rtrim(tabname) 
as tabname, row_number() over (partition by status) as seq 
from  syscat.tables 
WHERE status='C' ),r(a, seq1) as (select CAST(tabname as VARCHAR(3900)), seq 
from  gen where seq=1 union all select r.a || ','|| rtrim(gen.tabname), gen.seq 
from gen , r where (r.seq1+1)=gen.seq ), r1 as (select a, seq1 from r) 
select 'SET INTEGRITY FOR ' || a || ' IMMEDIATE CHECKED;' from r1 
where seq1=(select max(seq1) from r1)" > db2FixCheckPending.sql

db2 -tvf db2FixCheckPending.sql


http://db2commerce.com/2015/12/15/db2-load-utility-and-check-pending-states/

if you have tables dependent on others, you might have a problem of ordering. If you have multiple dependecy trees you might have to iterate several times…

Here’s some code snippet:
##################################################
db2 “connect to $1″;
num=`db2 -x “select count(*) from syscat.tables where status = ‘C'”`;

while [ ${num} -gt 0 ] ; do
db2 -x “select ‘SET INTEGRITY FOR ‘ || rtrim(char(tabschema, 128)) || ‘.’ || rtrim(char(tabname, 128)) || ‘ IMMEDIATE CHECKED;’
from syscat.tables where status = ‘C’ order by parents, children” > ${db2_si_cmd_file};
db2 -tvf ${db2_si_cmd_file} -z ${db2_si_log_file};

prev_num=${num};
num=`db2 -x “select count(*) from syscat.tables where status = ‘C'”`;

if [ ${num} -gt 0 ] ; then
echo “The INTEGRITY for the following tables could not be set: “;
db2 -x “select rtrim(char(tabschema, 128)) || ‘.’ || rtrim(char(tabname, 128)) from syscat.tables where status = ‘C'”;
fi;
done;

db2 “connect reset”;
##################################################


9.查看用户权限

db2 " SELECT SUBSTR(GRANTOR, 1, 10) AS GRANTOR, -- Grantor of the authority
SUBSTR(GRANTEE, 1, 10) AS GRANTEE, -- Holder of the authority
-- G = Grantee is a group R = Grantee is a role
GRANTEETYPE, -- U = Grantee is an individual user
BINDADDAUTH,
CONNECTAUTH,
CREATETABAUTH,
DBADMAUTH,
IMPLSCHEMAAUTH,
DATAACCESSAUTH,
LOADAUTH
FROM SYSCAT.DBAUTH
ORDER BY GRANTEE WITH UR " 


db2 "select * from syscat.dbauth where grantee='CHUBALA'"

db2 " SELECT SUBSTR(GRANTOR, 1, 10) AS GRANTOR, -- Grantor of the authority
SUBSTR(GRANTEE, 1, 10) AS GRANTEE, -- Holder of the authority
SECURITYADMAUTH,
QUIESCECONNECTAUTH,
LIBRARYADMAUTH,
SQLADMAUTH,
WLMADMAUTH,
EXPLAINAUTH,
ACCESSCTRLAUTH
FROM SYSCAT.DBAUTH
ORDER BY GRANTEE WITH UR " 

10.查看表权限 

db2 "select * from syscat.tabauth where grantee='DB2INST1'" 

db2 "select substr(GRANTOR,1,30), GRANTORTYPE, substr(GRANTEE,1,30), GRANTEETYPE, substr(TABSCHEMA,1,30), substr(TABNAME,1,30), CONTROLAUTH, ALTERAUTH, DELETEAUTH, INDEXAUTH, INSERTAUTH, REFAUTH, SELECTAUTH, UPDATEAUTH from syscat.tabauth where GRANTEE='DB2INST1'"

db2 "select substr(GRANTOR,1,30), GRANTORTYPE, substr(GRANTEE,1,30), GRANTEETYPE, substr(TABSCHEMA,1,30), substr(TABNAME,1,30), CONTROLAUTH from syscat.tabauth where GRANTEE='DB2INST1'"

11.查看日志归档情况

db2 "SELECT DATE(CAST(START_TIME as TIMESTAMP)) as DATE,

count(*) as NUMBER_OF_LOGS_PER_DAY,

(count(*)*23.4375) as AMOUNT_LOGS_DAY_MB,

DBPARTITIONNUM as DBPART

FROM SYSIBMADM.DB_HISTORY

WHERE operation = 'X' -- Archive logs

and OPERATIONTYPE = '1' -- 1 = first log archive method

and TIMESTAMP(END_TIME) > CURRENT_TIMESTAMP - 10 DAYS

GROUP BY DATE(CAST(START_TIME as TIMESTAMP)) , DBPARTITIONNUM

ORDER BY DATE DESC "

12.查看过去24小时是否进行过备份

db2 "select substr(comment,1,30) as comment, timestamp(start_time) as start_time, timestamp(end_time) as end_time, substr(firstlog,1,25) as firstlog, substr(lastlog,1,25) as lastlog, seqnum, substr(location,1,50) as location from sysibmadm.db_history where operation = 'B' and timestamp(start_time) > current_timestamp - 24 hours and sqlcode is null "

13.SQL复制同步情况

Dprop check

Capture side:

db2 "SELECT SYNCHTIME, CURRENT TIMESTAMP AS CURRENT_TIMESTAMP FROM ASN.IBMSNAP_REGISTER WHERE GLOBAL_RECORD='Y' with ur"

Apply side:

db2 "select APPLY_QUAL, SET_NAME, SOURCE_ALIAS, TARGET_ALIAS, ACTIVATE, STATUS, LASTRUN, LASTSUCCESS, SYNCHTIME, SLEEP_MINUTES,REFRESH_TYPE from ASN.IBMSNAP_SUBS_SET"

14.一致性检查脚本

DB21034E  The command was processed as an SQL statement because it was not a
valid Command Line Processor command.  During SQL processing it returned:
SQL3608N  Cannot check a dependent table "VIKRAM.REGISTERED_STUDENTS" using
the SET INTEGRITY statement while the parent table or underlying table
"VIKRAM.STUDENTS" is in the Set Integrity Pending state or if it will be put
into the Set Integrity Pending state by the SET INTEGRITY statement.
SQLSTATE=428A8


db2 connect to sample
db2 -tx +w "with gen(tabname, seq) as( select rtrim(tabschema) || '.' || rtrim(tabname)
as tabname, row_number() over (partition by status) as seq
from  syscat.tables
WHERE status='C' ),r(a, seq1) as (select CAST(tabname as VARCHAR(3900)), seq
from  gen where seq=1 union all select r.a || ','|| rtrim(gen.tabname), gen.seq
from gen , r where (r.seq1+1)=gen.seq ), r1 as (select a, seq1 from r)
select 'SET INTEGRITY FOR ' || a || ' IMMEDIATE CHECKED;' from r1
where seq1=(select max(seq1) from r1)" > db2FixCheckPending.sql
db2 -tvf db2FixCheckPending.sql

A sample output:

SET INTEGRITY FOR VIKRAM.ERROR_STACKS,VIKRAM.CLASSES,VIKRAM.CALL_STACKS,VIKRAM.ERRORS,VIKRAM.REGISTERED_STUDENTS,
VIKRAM.ROOMS,VIKRAM.STUDENTS IMMEDIATE CHECKED;

The only limitation is the size of the SET command – based on this script it cannot be larger that 3900 characters. 


15.db2pd 命令中的参数 -ruStatus 显示 DB2 pureScale 实例中的修补程序包更新的状态。

http://www.ibm.com/developerworks/cn/data/library/techarticle/dm-1506db2pd-fixpack-progress/

16.DB2 Event Monitor使用与查询

首先创建一个目录用于存放事件监控，例：
[db2inst1@myhost ~]$ mkdir emondir

创建一个sql语句的事件监控
[db2inst1@myhost ~]$ db2 "create event monitor temon1 for statements write to file '/home/db2inst1/emondir'"

启动temon1
[db2inst1@myhost ~]$ db2 "set event monitor temon1 state 1"

查看事件监控生成的内容：
[db2inst1@myhost ~]$db2evmon -path emondir

查看事件监控启动情况：
[db2inst1@myhost ~]$db2 "select evmonname, event_mon_state(evmonname) from syscat.eventmonitors

关闭temon1
[db2inst1@myhost ~]$ db2 "set event monitor temon1 state 1"

删除temon1
[db2inst1@myhost ~]$ db2 "drop event monitor temon1'"


16.查询不常用的index（v9.7/v10.1）

db2 "select  i.lastused,
        substr(t.tabschema,1,20) as tabschema,
        substr(t.tabname,1,30) as tabname,
        substr(i.indschema,1,20) as indschema,
        substr(indname,1,40) as indname,
        substr(colnames,1,60) as colnames,
        bigint(fullkeycard)as fullkeycard,
        bigint(card) as table_card,
        case
          when card > 0 then decimal(float(fullkeycard)/float(card),5,2)
          else -1
        end as pct_card,
        mi.index_scans,
        mt.table_scans,
        mi.index_only_scans,
        mi.page_allocations,
        volatile
from    syscat.indexes i join syscat.tables t
        on i.tabname=t.tabname and i.tabschema=t.tabschema
        join table(mon_get_index('','',-2)) as mi on i.iid=mi.iid and i.tabschema=mi.tabschema and i.tabname = mi.tabname
        join table(mon_get_table('','',-2)) as mt on i.tabschema=mt.tabschema and i.tabname=mt.tabname
where
        indextype not in ('BLOK', 'DIM')
        and t.tabschema not like 'SYS%'
        and uniquerule='D'
        and not exists (select 1
                from syscat.references r join syscat.keycoluse k
                        on r.tabschema=k.tabschema and r.tabname=k.tabname
                where t.tabschema=r.tabschema
                        and r.tabname = t.tabname
                        and k.colname in (      select colname
                                        from syscat.indexcoluse as ic
                                        where ic.indschema=i.indschema
                                        and ic.indname=i.indname))
        and i.lastused < current timestamp - 30 days
order by mi.index_scans, i.lastused, fullkeycard, card
with ur"



17.常用监控

17.1 监控表空间状态 tbsp_state='NORMAL'

db2 -v "select
substr(tbsp_id,1,10) as tbsp_id,
substr(tbsp_name,1,20) as tbsp_name,
substr(tbsp_state,1,10) as tbsp_state
from sysibmadm.tbsp_utilization with ur"


        d069cms:/dbhome/d069cms$ db2 -v "select
        > substr(tbsp_id,1,10) as tbsp_id,
        > substr(tbsp_name,1,20) as tbsp_name,
        > substr(tbsp_state,1,10) as tbsp_state
        > from sysibmadm.tbsp_utilization with ur"
        select
        substr(tbsp_id,1,10) as tbsp_id,
        substr(tbsp_name,1,20) as tbsp_name,
        substr(tbsp_state,1,10) as tbsp_state
        from sysibmadm.tbsp_utilization with ur
        
        TBSP_ID    TBSP_NAME            TBSP_STATE
        ---------- -------------------- ----------
        0          SYSCATSPACE          NORMAL    
        1          TEMPSPACE1           NORMAL    
        2          USERSPACE1           NORMAL    
        3          COCOMOREGSPACE       NORMAL    
        4          TMPSPACE1            NORMAL    
        5          SYSTOOLSPACE         NORMAL    
        
          6 record(s) selected.
        
        
        d069cms:/dbhome/d069cms$ 
        

17.2. 表空间利用率DMS <80%

db2 -v "select 
substr (tbsp_name,1,20), 
substr(tbsp_state,1,10), 
tbsp_utilization_percent 
from sysibmadm.mon_tbsp_utilization with ur"


	d069cms:/dbhome/d069cms$ db2 -v "select 
	> substr (tbsp_name,1,20), 
	> substr(tbsp_state,1,10), 
	> tbsp_utilization_percent 
	> from sysibmadm.mon_tbsp_utilization with ur"
	select 
	substr (tbsp_name,1,20), 
	substr(tbsp_state,1,10), 
	tbsp_utilization_percent 
	from sysibmadm.mon_tbsp_utilization with ur

	1                    2          TBSP_UTILIZATION_PERCENT
	-------------------- ---------- ------------------------
	SYSCATSPACE          NORMAL                            -
	TEMPSPACE1           NORMAL                            -
	USERSPACE1           NORMAL                            -
	COCOMOREGSPACE       NORMAL                            -
	TMPSPACE1            NORMAL                            -
	SYSTOOLSPACE         NORMAL                         0.24

	  6 record(s) selected.


	d069cms:/dbhome/d069cms$

17.3. 缓冲池命中率 >90%


db2 -v "select 
substr(bp_name,1,15), 
total_hit_ratio_percent  
from sysibmadm.bp_hitratio with ur"


	d069cms:/dbhome/d069cms$ db2 -v "select 
	> substr(bp_name,1,15), 
	> total_hit_ratio_percent  
	> from sysibmadm.bp_hitratio with ur"
	select 
	substr(bp_name,1,15), 
	total_hit_ratio_percent  
	from sysibmadm.bp_hitratio with ur

	1               TOTAL_HIT_RATIO_PERCENT
	--------------- -----------------------
	IBMDEFAULTBP                      99.99
	DEF32K                            99.97
	IBMSYSTEMBP4K                         -
	IBMSYSTEMBP8K                         -
	IBMSYSTEMBP16K                        -
	IBMSYSTEMBP32K                        -

	  6 record(s) selected.


	d069cms:/dbhome/d069cms$ 



17.4. 数据库容量 < 60%


db2 -v "call get_dbsize_info(?,?,?,-1)"

	d069cms:/dbhome/d069cms$ db2 -v "call get_dbsize_info(?,?,?,-1)"
	call get_dbsize_info(?,?,?,-1)

	  Value of output parameters
	  --------------------------
	  Parameter Name  : SNAPSHOTTIMESTAMP
	  Parameter Value : 2016-02-23-21.13.33.779759

	  Parameter Name  : DATABASESIZE
	  Parameter Value : 2873561088

	  Parameter Name  : DATABASECAPACITY
	  Parameter Value : 182417186816

	  Return Status = 0

	d069cms:/dbhome/d069cms$ 
	
	

	
17.5. 锁，锁等时间，锁列表

db2 -v "select locks_held,lock_waits,lock_wait_time, lock_list_in_use from sysibmadm.snapdb with ur"


17.6. 日志使用量
db2 -v "select total_log_used,total_log_available from sysibmadm.snapdb with ur"

17.7. 日志文件系统使用量

db2 get db cfg |find /i "路径"
df -k xxxx(路径)


18.






