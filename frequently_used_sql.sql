-- Frequently Used SQL Statements

-- Redo
select name,log_mode from v$database;

select thread#,status,enabled from v$thread;

select * from (select sequence#,thread#,first_time,next_time from v$archived_log order by sequence# desc) where rownum < 11;

select thread#,max(sequence#) from gv$archived_log where applied='YES' group by thread#;

select inst_id,thread#,sequence#,first_change#,first_time,next_change#,next_time,deleted from gv$archived_log where first_change#>12677179 and first_change#<15513401 and deleted='NO' order by sequence#;

-- Standby
alter database recover managed standby database using current logfile disconnect;

alter database recover managed standby database cancel;

select db_unique_name,name,open_mode,database_role from v$database;

select distinct type,database_mode,recovery_mode from v$archive_dest_status where status='VALID';

select process,status,thread#,sequence# from v$managed_standby;

select * from v$dataguard_stats where name = 'apply lag';

select * from v$archive_gap;

-- Logical Standby
-- Primary
execute DBMS_LOGSTDBY.BUILD;

-- Standby (RAC)
alter system set cluster_database=false scope=spfile;

shutdown immediate;

startup mount exclusive;

alter database recover to logical standby fremont;

shutdown;

startup mount;

alter database open resetlogs;

alter system set cluster_database=true scope=spfile;

shutdown;

startup;

alter database start logical standby apply immediate;

select * from v$logstdby_state;

select type,status_code,status from v$logstdby_process;

-- RMAN
select recid,set_stamp,set_count,backup_type,incremental_level from v$backup_set;

-- Misc
select username,account_status from dba_users;

select property_value from database_properties where property_name='DEFAULT_TEMP_TABLESPACE';

select tablespace_name,status from dba_tablespaces;

select file_name,tablespace_name from dba_data_files;

select sum(bytes / (1024*1024)) "DB Size in MB" from dba_data_files;

select file#,ts#,status,enabled,checkpoint_change#,checkpoint_time,name from v$datafile where status='RECOVER';

-- MDS
-- svccfg -s d/mgmt setprop d/debug=true
-- svcadm refresh d/mgmt
-- jdbc:derby://172.16.100.65:1527//var/d/server/db/hercules;user=mds;password=iamMDS
-- or
-- /opt/d/server/bin/derby_client

select snapshot_id,count(*) as files from snl_orcl_db_files where database_id=1 and file_type=1 group by snapshot_id;

select snapshot_id,checkpoint_scn,latest_scn from snl_orcl_db_snapshots where database_id=0;

select first_change_time,last_change_time,creation_time from DLPX_SNAPSHOT;

-- Oracle RAC support in Alderaan
select cluster,name,host from ORCL_CLUSTER_NODE;

select database_name,instance_number,instance_name,node from ORCL_DB_CONFIG,ORCL_INSTANCE_CONFIG where ORCL_DB_CONFIG.DB_CONFIG_ID = ORCL_INSTANCE_CONFIG.ORCL_DB_CONFIG_ID and ORCL_DB_CONFIG.DB_CONFIG_ID = 1;
