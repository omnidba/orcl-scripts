export ORACLE_SID=bigone
export ORACLE_HOME=/opt/app/oracle/product/10.2.0.4/db_1
export PATH=$PATH:$ORACLE_HOME/bin

sqlplus '/as sysdba' <<EOF
@$ORACLE_HOME/rdbms/admin/dbmsrand.sql
drop user samtest;
create user samtest identified by samtest default tablespace DELPHIX;
grant dba,connect,resource to samtest;
conn samtest/samtest
exit;
EOF

sqlplus samtest/samtest <<EOF
drop sequence samtest.tmp_id;
create sequence samtest.tmp_id increment by 1 start with 1 maxvalue 999999999999999 nocycle nocache;
drop table samtest.sam_tmp;
create table samtest.sam_tmp(addr varchar2(30),age number,marry varchar2(10),titile varchar2(30),salary number,tele number,mobile nu
mber,friend varchar2(30),wife varchar2(30));
set serveroutput on;
spool tmp1.sql
begin
for lo_n in 1..80000
loop
dbms_output.put_line('drop table samtest.sam_'||lo_n||';');
dbms_output.put_line('create table samtest.sam_'||lo_n||' as select samtest.tmp_id.nextval as id,addr,age,marry,titile,salary,tele,m
obile,friend,wife from samtest.sam_tmp'||';');
dbms_output.put_line('create index samtest.sam_idx_'||lo_n||' on samtest.sam_'||lo_n||'('||'id'||')'||' tablespace BFTTEST;');
end loop;
end;
/
spool off
set serveroutput off;
@tmp1.sql
exit;
EOF

rm tmp1.sql
