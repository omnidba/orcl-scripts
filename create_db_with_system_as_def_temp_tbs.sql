-- create a database whose default temporary tablespace is SYSTEM tablespace
create database mynewdb
user sys identified by oracle
user system identified by oracle
logfile group 1 ('/opt/oracle/oradata/mynewdb/redo1.log') size 512M,
group 2 ('/opt/oracle/oradata/mynewdb/redo2.log') size 512M,
group 3 ('/opt/oracle/oradata/mynewdb/redo3.log') size 512M
MAXLOGFILES 5
MAXLOGMEMBERS 5
MAXLOGHISTORY 1
MAXDATAFILES 100
MAXINSTANCES 1
ARCHIVELOG
CHARACTER SET US7ASCII
NATIONAL CHARACTER SET AL16UTF16
DATAFILE '/opt/oracle/oradata/mynewdb/system01.dbf' size 325M reuse
sysaux datafile '/opt/oracle/oradata/mynewdb/sysaux01.dbf' size 325M reuse
undo tablespace undotbs1
datafile '/opt/oracle/oradata/mynewdb/undotbs01.dbf' size 200M reuse autoextend on maxsize unlimited;
