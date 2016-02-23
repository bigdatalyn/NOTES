### Standard
mon_get_bufferpool@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_BUFFERPOOL(NULL,-1)) AS T
mon_get_table@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_TABLE(NULL,NULL,-1)) AS T WHERE TABSCHEMA NOT IN ('SYSIBM','SYSTOOLS')
mon_get_tablespace@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_TABLESPACE(NULL,-1)) AS T
mon_get_pkg_cache_stmt@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-1)) AS T ORDER BY STMT_EXEC_TIME DESC FETCH FIRST 100 ROWS ONLY@EXECUTABLE_ID@COMP_ENV_DESC,MAX_COORD_STMT_EXEC_TIME_ARGS
mon_get_workload@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_WORKLOAD(NULL,-1)) AS T

### for 10.5 only (not applicable for DB2 10.1 or earlier)
mon_get_database@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_DATABASE(-1)) AS T

### pureScale
# mon_get_cf@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_CF(NULL)) AS T
# mon_get_cf_cmd@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_CF_CMD(NULL)) AS T
# mon_get_page_access_info@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_PAGE_ACCESS_INFO(NULL,NULL,-1)) AS T
# mon_get_group_bufferpool@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_GROUP_BUFFERPOOL(-1)) AS T
# mon_get_extended_latch_wait@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_EXTENDED_LATCH_WAIT(-1)) AS T
# mon_get_serverlist@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_SERVERLIST(-1)) AS T

### on Demand 
# mon_get_memory_pool@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_MEMORY_POOL(NULL,NULL,-1)) AS T
# mon_get_memory_set@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_MEMORY_SET(NULL,NULL,-1)) AS T
# mon_get_instance@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_INSTANCE(-1)) AS T
# mon_get_hadr@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_HADR(-1)) AS T
# mon_get_appl_lockwait@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_APPL_LOCKWAIT(NULL,-1)) AS T
# mon_get_locks@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_LOCKS(NULL,-1)) AS T
# mon_get_index@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_INDEX(NULL,NULL,-1)) AS T
# mon_get_transaction_log@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_TRANSACTION_LOG(-1)) AS T
# mon_get_connection@SELECT CURRENT TIMESTAMP AS TIMESTAMP, T.* FROM TABLE(MON_GET_CONNECTION(NULL, -1)) AS T ORDER BY TOTAL_ACT_TIME DESC FETCH FIRST 100 ROWS ONLY@LAST_EXECUTABLE_ID@

### User customize
# sample@SELECT CURRENT TIMESTAMP AS TIMESTAMP, COUNT(*) AS COUNT FROM syscat.tables