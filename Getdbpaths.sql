% db2 "select dbpartitionnum, substr(type,1,20) as type, substr(path,1,80) path from sysibmadm.dbpaths"

DBPARTITIONNUM TYPE                 PATH
-------------- -------------------- ----------------------------------------------------
             0 LOGPATH              /dbdata/actlog1/NODE0000/
             0 MIRRORLOGPATH        /dbdata/actlog2/NODE0000/
             0 DB_STORAGE_PATH      /dbdata/db2inst1/
             0 LOCAL_DB_DIRECTORY   /dbdata/db2inst1/db2inst1/NODE0000/sqldbdir/
             0 DBPATH               /dbdata/db2inst1/db2inst1/NODE0000/SQL00003/

  5 record(s) selected.
