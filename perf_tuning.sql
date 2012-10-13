-- Execution plan
@$ORACLE_HOME/rdbms/admin/utlxpls.sql;

explain plan for select count(*) from soe.orders;

select plan_id,time from plan_table;

select plan_table_output from table(dbms_xplan.display());

select plan_table_output from table(dbms_xplan.display(null,null,'basic'));

set autot on
set autot traceonly
set autot traceonly explain
set autot off

-- AWR
@$ORACLE_HOME/rdbms/admin/awrrpt.sql;

@$ORACLE_HOME/rdbms/admin/awrgrpt.sql;

-- Index
select index_name,index_type,distinct_keys,num_rows from dba_indexes where table_name='CUSTOMERS';

execute dbms_stats.gather_index_stats('SOE','CUST_LNAME_IX');
select blevel,clustering_factor,index_name from dba_indexes where index_name='CUST_LNAME_IX';

-- Statistics
select object_name,object_id from dba_objects where object_name='T1';

select * from v$segstat where obj#=30427;
