1.查看表空情况和大小

1.1.使用一条命令即可查看表空间的状态信息，格式化输出 db2 list tablespaces show detail 

LANG=en_US;db2 termiante; db2 connect to SAMPLE;db2 list tablespaces show detail | while read line  ; do w1=$(echo "$line" | cut -d" " -f1); if [ "$w1" ==  "Tablespace" ];then tabid=$(echo "$line" | cut -d'=' -f2);fi; if [ "$w1" ==  "Name" ];then   name=$(echo "$line" | cut -d'=' -f2); fi; if [ "$w1" ==  "Type" ];then  type=$(echo "$line" | cut -d'=' -f2);type1=$(echo "$type" | awk '{print $1}'); if [ "$type1" == "System" ];then Ttype='SMS';  else Ttype='DMS'; fi;  fi; if [ "$w1" == "Contents" ];then contents=$(echo "$line" | cut -d'=' -f2); fi; if  [ "$w1" ==  "State" ];then state=$(echo "$line" | cut -d'=' -f2);fi; if [ "$w1" == "Total" ];then   total=$(echo "$line" | cut -d'=' -f2);fi;if [ "$w1" == "Used" ]; then used=$(echo "$line" | cut -d'=' -f2); fi;  if [ "$w1" ==  "Free" ]; then free=$(echo "$line" | cut -d'=' -f2); fi; if [ "$w1" == "Page" ];then page=$(echo "$line" | cut -d'=' -f2); printf "%-25s%-5s%-5s%-5s%-10s%-20s%-20s%-30s\n"  $name $tabid $page $Ttype $state $total $used; fi  done

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

11.





