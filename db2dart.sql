
db2dart:

1.非正常关闭数据库的情况下，数据库处于 “不一致” 的状态，
数据容器文件中会存在“脏数据”（事务尚未提交，便写到磁盘的数据）。
此时使用 “db2dart /ddel” 扫描导出的数据肯定是不一致的数据。      
只做崩溃恢复使得数据库数据一致后，再正常关闭数据库进行 “db2dart /ddel”  操作。

2.
db2dart 操作不会导致数据不一致。
正常关闭数据库，db2dart导出的数据是正确可信的，
非正常关闭数据库，db2dart出来的数据可能会不一致。
 
3.
db2dart /ddel  是万不得已才使用方法，而且不能导出blob和clob类型的字段，
数据库一致状态下，抽取出来的数据时一致的，非正常关闭的数据库抽取出来的数据可能是不一致，
这取决你当时数据库的访问情况

4.

db2dart sample /ddel

Table object data formatting start.
Please enter
Table ID or name, tablespace ID, first page, num of pages:
SYSTABLES,0,0,999999

The output data file is TS0T5.DEL.

DBNAME=sample
SCHEMA=E97Q7A
RPTDIR=/tmp/db2dart

sed 's/"//g' TS0T5.DEL|while read line
do
echo $line|awk -F"," '{
objtype=substr($3,1,1)
gsub(" ","",$2)
dbschema=$2
if(objtype=="T" && dbschema=="'$SCHEMA'" )
{
tablename=$1
tableid=$7
tbspaceid=$8
printf("%s,%s,0,9999999\ny\n%s\n",tableid,tbspaceid,tablename)
}
}'>inputfile
if [ -s inputfile ]
then
db2dart $DBNAME /DDEL /RPT $RPTDIR < inputfile
fi
done

The /DDEL parameter supports only the following column data types. If a table contains columns with any other data type, the column is skipped and not included in the delimited ASCII file.

SMALLINT
FLOAT
REAL
INTEGER
TIME
DECIMAL
CHAR()
VARCHAR()
DATE
TIMESTAMP
BIGINT

If a column of type CHAR and VARCHAR contains any binary data, or is defined with FOR BIT DATA, the /DDEL parameter generates the DEL file which contains the binary data. When you load data from the DEL file to the table using the LOAD command, ensure that you always specify the modified by delprioritychar option. When you insert data into the table from the DEL file using the IMPORT command, make sure that you always specify the modified by delprioritychar codepage=x option where x is the code page of the data in the input data set.


5.
 
 
 
 
