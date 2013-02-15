-- add_ORL_grp.sql
-- add 32 ORL groups
set serveroutput on;

declare
  swtstmt  varchar2(1024) := 'alter system switch logfile';
  add_ORL_grp_stmt varchar2(1024) := 'alter database add logfile';
  drop_ORL_grp_stmt varchar2(1024) := 'alter database drop logfile group';
  group_total V$LOGFILE.group#%TYPE;
  group_number V$LOGFILE.group#%TYPE;
  v_ORL_status varchar2(16) := '';
  v_count int;
begin
  for i in 1..2 loop
    --execute immediate add_ORL_grp_stmt;
    --dbms_lock.sleep(1);
    NULL;
  end loop;
  
  select max(group#) into group_total from v$logfile;
  dbms_output.put_line('Total group#: '||to_char(group_total));
  
    v_count := group_total - 32;
    dbms_output.put_line(v_count);
  
  for i in v_count..group_total loop
    --drop_ORL_grp_stmt := 'alter database drop logfile group';
    group_number := i;
    dbms_output.put_line(group_number);
    select status into v_ORL_status from V$LOG where group# = group_number;
    
    if v_ORL_status <> '' then   
      if v_ORL_status <> 'CURRENT' then
        dbms_output.put_line(v_ORL_status);
      else
        continue;
      end if;
    else
      continue;
    end if;
    --drop_ORL_grp_stmt := drop_ORL_grp_stmt||' '||to_char(i);
    --dbms_output.put_line(drop_ORL_grp_stmt);
    --execute immediate drop_ORL_grp_stmt;
    --dbms_lock.sleep(1);
  end loop;  
end;