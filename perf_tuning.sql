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

-- Partitioning
create table sales
(prod_id number(6),
 cust_id number,
 time_id date,
 channel_id char(1),
 promo_id number(6),
 quantity_sold number(3),
 amount_sold number(10,2)
 )
 partition by range(time_id)
 subpartition by hash(cust_id) subpartitions 16
 (partition sal99q1 values less than
  (to_date('01-APR-1999', 'DD-MON-YYYY')),
  partition sal99q2 values less than
  (to_date('01-JUL-1999', 'DD-MON-YYYY')),
  partition sal99q3 values less than
  (to_date('01-OCT-1999', 'DD-MON-YYYY')),
  partition sal99q4 values less than
  (to_date('01-JAN-2000', 'DD-MON-YYYY'))
 );

create table customers
(cust_id number,
cust_first_name varchar2(20),
cust_last_name varchar2(20)
)
partition by hash(cust_id) partitions 16;

select c.cust_last_name, count(*)
from sales s, customers c
where s.cust_id=c.cust_id and
s.time_id between to_date('01-JUL-1999','DD-MON-YYYY') and
to_date('01-OCT-1999','DD-MON-YYYY')
group by c.cust_last_name having count(*) > 100;

alter table sales parallel (degree 16);

-- Statistics
select object_name,object_id from dba_objects where object_name='T1';

select * from v$segstat where obj#=30427;

exec dbms_stats.gather_schema_stats(ownname=>'SOE',cascade=>dbms_stats.auto_cascade,degree=>48);

-- Tablescan
create bigfile tablespace bigtbs datafile '+DATA/trois/datafile/bigtbs_f1.dbf' size 10M autoextend on;

create table t1 pctfree 99 pctused 1 tablespace bigtbs
as
  select
    rownum id,
    trunc(100 * dbms_random.normal) val,
    rpad('x',100) padding
  from
    all_objects
  where
    rownum <= 10000
;


