新创建的数据库，执行db2look时，遇到package db2lkfun.bnd bind failed


http://www.cnblogs.com/DBA-Ivan/p/4217467.html


db2v97i1@oc0644314035 ~]$ db2look -d sample -e -l -o db2look.ddl
-- No userid was specified, db2look tries to use Environment variable USER
-- USER is: DB2V97I1
-- Creating DDL for table(s)
-- Output is sent to file: db2look.ddl
-- Binding package automatically ...
--An error has occured during Binding

Error Message =
SQL0001N  Binding or precompilation did not complete successfully.


SQLCA  
Size    = 136
SQLCODE = -1
Tokens  = /home/db2v97i1/sqllib/bnd/db2lkfun.bnd
RDS fn  = sqlajbnd
RC      = 0x0000 = 0
Reason  = 0x0000 = 0
Reason2 = 0x0000 = 0
Warning flags =        

--An error has occured during Binding

Error Message =
SQL0031C  File "/home/db2v97i1/db2lkfun.bnd" could not be opened.


SQLCA  
Size    = 136
SQLCODE = -31
Tokens  = /home/db2v97i1/db2lkfun.bnd
RDS fn  = sqlajbnd
RC      = 0x0000 = 0
Reason  = 0x0000 = 0
Reason2 = 0x0000 = 0
Warning flags =        

Try to run the command db2 "bind  db2lkfun.bnd   blocking all grant public", got the error about authorization.

db2v97i1@oc0644314035 bnd]$  db2 "bind  db2lkfun.bnd   blocking all grant public"

LINE    MESSAGES FOR db2lkfun.bnd
------  --------------------------------------------------------------------
        SQL0061W  The binder is in progress.
12291   SQL0440N  No authorized routine named "RTRIM" of type
                  "FUNCTION" having compatible arguments was found. 
                  SQLSTATE=42884
12987   SQL0440N  No authorized routine named "RTRIM" of type
                  "FUNCTION" having compatible arguments was found. 
                  SQLSTATE=42884
        SQL0082C  An error has occurred which has terminated
                  processing.
        SQL0092N  No package was created because of previous errors.
        SQL0091N  Binding was ended with "4" errors and "0" warnings.

Check the authorizations for the user

[db2v97i1@oc0644314035 ~]$ db2 " SELECT SUBSTR(GRANTOR, 1, 10) AS GRANTOR, -- Grantor of the authority
> SUBSTR(GRANTEE, 1, 10) AS GRANTEE, -- Holder of the authority
> -- G = Grantee is a group R = Grantee is a role
> GRANTEETYPE, -- U = Grantee is an individual user
> BINDADDAUTH,
> CONNECTAUTH,
> CREATETABAUTH,
> DBADMAUTH,
> IMPLSCHEMAAUTH,
> DATAACCESSAUTH,
> LOADAUTH
> FROM SYSCAT.DBAUTH
> ORDER BY GRANTEE WITH UR "

GRANTOR    GRANTEE    GRANTEETYPE BINDADDAUTH CONNECTAUTH CREATETABAUTH DBADMAUTH IMPLSCHEMAAUTH DATAACCESSAUTH LOADAUTH
---------- ---------- ----------- ----------- ----------- ------------- --------- -------------- -------------- --------
SYSIBM     DB2V97I1   U           N           N           N             Y         N              Y              N      
SYSIBM     PUBLIC     G           Y           Y           Y             N         Y              N              N      

 

[db2v97i1@oc0644314035 ~]$ cd sqllib/bnd
[db2v97i1@oc0644314035 bnd]$ db2 BIND db2lkfun.bnd BLOCKING ALL GRANT PUBLIC

LINE    MESSAGES FOR db2lkfun.bnd
------  --------------------------------------------------------------------
        SQL0061W  The binder is in progress.
12291   SQL0440N  No authorized routine named "RTRIM" of type
                  "FUNCTION" having compatible arguments was found. 
                  SQLSTATE=42884
12987   SQL0440N  No authorized routine named "RTRIM" of type
                  "FUNCTION" having compatible arguments was found. 
                  SQLSTATE=42884
        SQL0082C  An error has occurred which has terminated
                  processing.
        SQL0092N  No package was created because of previous errors.
        SQL0091N  Binding was ended with "4" errors and "0" warnings.

 

Grant SECADM to the user, solve the issue.

db2 grant SECADM on database to user db2v97i1

 

 

Security administration authority (SECADM)

SECADM authority is the security administration authority for a specific database. This authority allows you to create and manage security-related database objects and to grant and revoke all database authorities and privileges. Additionally, the security administrator can execute, and manage who else can execute, the audit system routines.

SECADM authority has the ability to SELECT from the catalog tables and catalog views, but cannot access data stored in user tables.

SECADM authority can be granted only by the security administrator (who holds SECADM authority) and can be granted to a user, a group, or a role. PUBLIC cannot obtain the SECADM authority directly or indirectly.

The database must have at least one authorization ID of type USER with the SECADM authority. The SECADM authority cannot be revoked from every authorization ID of type USER
SECADM authority gives a user the ability to perform the following operations:

    Create, alter, comment on, and drop:
        Audit policies
        Security label components
        Security policies
        Trusted contexts
    Create, comment on, and drop:
        Roles
        Security labels
    Grant and revoke database privileges and authorities
    Execute the following audit routines to perform the specified tasks:
        The SYSPROC.AUDIT_ARCHIVE stored procedure and table function archive audit logs.
        The SYSPROC.AUDIT_LIST_LOGS table function allows you to locate logs of interest.
        The SYSPROC.AUDIT_DELIM_EXTRACT stored procedure extracts data into delimited files for analysis.

    Also, the security administrator can grant and revoke EXECUTE privilege on these routines, therefore enabling the security administrator to delegate these tasks, if desired. Only the security administrator can grant EXECUTE privilege on these routines. EXECUTE privilege WITH GRANT OPTION cannot be granted for these routines (SQLSTATE 42501).
    Use of the AUDIT statement to associate an audit policy with a particular database or database object at the server
    Use of the TRANSFER OWNERSHIP statement to transfer objects not owned by the authorization ID of the statement

No other authority gives these abilities.

Only the security administrator has the ability to grant other users, groups, or roles the ACCESSCTRL, DATAACCESS, DBADM, and SECADM authorities.

In Version 9.7, the DB2® authorization model has been updated to clearly separate the duties of the system administrator, the database administrator, and the security administrator. As part of this enhancement, the abilities given by the SECADM authority have been extended. In releases prior to Version 9.7, SECADM authority did not provide the ability to grant and revoke all privileges and authorities. Also, SECADM authority could be granted only to a user, not to a role or a group. Additionally, SECADM authority did not provide the ability to grant EXECUTE privilege to other users on the audit system-defined procedures and table function.
