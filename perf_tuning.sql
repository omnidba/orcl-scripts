-- Execution plan
@$ORACLE_HOME/rdbms/admin/utlxpls.sql;

explain plan for select count(*) from soe.orders;

select plan_id,time from plan_table;
