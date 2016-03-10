  # USAGE="
  Usage: TopRankSQLS.ksh 
  [-I&amp;lt;Get the instance name&amp;gt;(mandatory)]
  [-D&amp;lt;Database name to connect to&amp;gt;(mandatory)] 
  [-M&amp;lt;Mail id to
                  which the logfile details would be sent&amp;gt; "
  
  
  &quot; 
  
  # Sample: ./TopRankSQLS.ksh -i db2pr1 -d PR1 -m &quot;rchiyodu@in.ibm.com&quot;
                  
  ##############################################################################################
                  
  #set -x 
  if [ -f $HOME/sqllib/db2profile ]; 
  then . $HOME/sqllib/db2profile 
  fi 
  
  # Parse Input 
  while getopts :h:I:i:D:d:M:m: OPT ; do 
      case $OPT in 
      h) echo &quot;${USAGE}&quot; 
      exit 0 
      ;; 
      [Ii])LINSTNAME=`echo &quot;${OPTARG}&quot;` 
                                         ;;
      [Dd])LSTDATABASENAME=`echo &quot;${OPTARG}&quot;` 
                                         ;; 
      [Mm])LMAILID=`echo &quot;${OPTARG}&quot;` 
                                         ;; 
      *)      # Display the usage string 
              echo &quot;${USAGE}&quot; 1&amp;gt;&amp;amp;2 
              exit 1 
              ;; 
          esac 
      done 
  
      shift `expr ${OPTIND} - 1` 
  
  # Make the validation for the instance name 
      if test -z &quot;${LINSTNAME}&quot; 
          then 
            echo &quot;${USAGE}&quot; 
            exit 1 
            fi 
            if [ &quot;${LINSTNAME}&quot; != $DB2INSTANCE ];
            then echo &quot;Incorrect Instance name provided&quot; 
            echo &quot;${USAGE}&quot; 
            exit 1
            fi 
  
  # Make sure that the threeshold Value is entered 
  
  if test -z &quot;${LSTDATABASENAME}&quot; 
      then 
          echo &quot;${USAGE}&quot; 
          exit 1 
          fi 
  
          DBCHECK=`db2 list active databases |grep &quot;${LSTDATABASENAME}&quot; |wc -l`
  if [ $DBCHECK -eq 0 ]; then 
          tput bold 
          echo &quot;Incorrect Database Name Provided&quot; 
          tput rmso 
          echo &quot;${USAGE}&quot; 
          exit 1 
  db2 connect to &quot;${LSTDATABASENAME}&quot; &amp;gt;
                  /dev/null 
          if test $? -gt 0 
          then 
          tput bold 
          echo &quot;Unable to connect to database. Check the Database Name provided as input&quot; 
          tput rmso 
          exit 1 
          fi 
  fi 
  
  #Make sure that the threshold value is entered 
      if test -z &quot;${LMAILID}&quot; 
      then 
      echo &quot;${USAGE}&quot; 
      exit 1
  fi 
  
  echo &quot;Please find the Top 10 SQL&apos;s in the database based on Total Execution Time,Average Execution Time,Average CPU
                  Time,Number of Executions, Number of Sorts&quot;&amp;gt;SQLRanK.out 
  
  echo &quot;##############################################################\n\n&quot;&amp;gt;&amp;gt;SQLRanK.out
                  
  #Get the TOP 10 SQLS by the Total Execution time 
  echo &quot; 1) Top 10 Ranking SQL&apos;s by the Total Execution Time\n\n&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  echo &quot;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&quot;&amp;gt;&amp;gt;SQLRanK.out
  
  db2 &quot;SELECT substr(stmt_text,1,50) as sql_statement, total_exec_time, total_sys_cpu_time, total_usr_cpu_time,num_executions, num_compilations FROM
  sysibmadm.snapdyn_sql ORDER BY total_exec_time desc FETCH FIRST 10 ROWS ONLY&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  if test $? -gt 0 ; 
  
  then echo &quot;Error in getting TOP 10 SQL&apos;s by Total Execution Time&quot;&amp;gt;&amp;gt;SQLRanK.out
                  fi 
  
  #Get the Top 10 SQLS by Average Execution Time 
  
  echo &quot; 2) Top 10 Ranking SQL&apos;s by the Average Execution Time\n\n&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  echo &quot;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&quot;&amp;gt;&amp;gt;SQLRanK.out
  
  db2 &quot;SELECT substr(stmt_text,1,50) as sql_statement, total_exec_time, num_executions,DECIMAL((real(total_exec_time) / real(num_executions)),18,9) as
                  avg_exec_time FROM sysibmadm.snapdyn_sql WHERE num_executions &amp;gt;0 ORDER BY 4 desc FETCH FIRST 10 ROWS ONLY&quot;&amp;gt;&amp;gt;SQLRanK.out 
  if test $? -gt 0 ;
                  
  then 
  echo &quot;No Top 10 SQLS Found by Average Execution Time&quot;&amp;gt;&amp;gt;SQLRanK.out 
  fi 
  
  #Get the Top 10 SQLS by Average CPU Time
  
  echo &quot; 
  3) Top 10 Ranking SQL&apos;s by Average CPU Time \n\n&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  echo &quot;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&quot;&amp;gt;&amp;gt;SQLRanK.out
  
  db2 &quot;SELECT substr(stmt_text,1,50) as sql_statement, total_sys_cpu_time, total_usr_cpu_time, num_executions,DECIMAL(((real(total_sys_cpu_time) +
  real(total_usr_cpu_time)) / re al(num_executions)),18,9) as avg_cpu_time FROM sysibmadm.snapdyn_sql WHERE num_executions &amp;gt; 0 ORDER BY avg_cpu_time desc
  FETCH FIRST 10 ROWS ONLY&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  if test $? -gt 0 ; then
     echo &quot;No Top 10 SQLs Found By Average CPU Time&quot;&amp;gt;&amp;gt;SQLRanK.out
                  fi#Get the Top 10 SQLS by Number of Executions 
  
  echo &quot; 4) Top 10 Ranking SQL&apos;s by Number of Execution\n\n&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  echo &quot;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&quot;&amp;gt;&amp;gt;SQLRanK.out
                  
  db2 &quot;SELECT substr(stmt_text,1,50) as sql_statement, total_exec_time, num_executions, stmt_sorts,num_compilations, 
  DECIMAL((real(total_exec_time) / real(num_executions)),18,9) as avg_exec_time FROM 
  sysibmadm.snapdyn_sql WHERE num_executions &amp;gt; 0 ORDER BY 3 desc FETCH FIRST 10
  ROWS ONLY&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
      if test $? -gt 0 ; then 
              echo &quot;No Top 10 SQLs Found by Number of Executions&quot;&amp;gt;&amp;gt;SQLRanK.out 
      fi 
  
  #Get the Top 10 SQLS by Number of sorts 
  
  echo &quot;5 ) Top 10 Ranking SQL&apos;s by Number of sorts\n\n&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
  echo &quot;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&amp;amp;&quot;&amp;gt;&amp;gt;SQLRanK.out
  
  db2 &quot;SELECT substr(stmt_text,1,50) as sql_statement, total_exec_time, num_executions, stmt_sorts,num_compilations, DECIMAL((real(total_exec_time) /
  real(num_executions)),18,9) as avg_exec_time FROM sysibmadm.snapdyn_sql WHERE num_executions &amp;gt; 0 ORDER BY stmt_sorts desc FETCH FIRST 10 ROWS
  ONLY&quot;&amp;gt;&amp;gt;SQLRanK.out 
  
      if test $? -gt 0 ; then 
              echo &quot;No TOP 10 SQL&apos;s found by Number of sorts&quot;&amp;gt;&amp;gt;SQLRanK.out 
      fi 
  
  cat SQLRanK.out | mailx -s &quot;Top 10 Rank SQLS in the database &quot;${LSTDATABASENAME}&quot; &quot; &quot;${LMAILID}&quot; 
  
  echo &quot;#################################################################&quot;&amp;gt;&amp;gt;SQLRanK.out
