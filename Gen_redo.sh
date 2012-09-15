#!/bin/sh
# generate workload on specified database,must run as oracle installation owner.
#          "-s ORACLE_SID": specify a instance name which you will run Gen_redo.sh on.
#         "-h ORACLE_HOME": specify ORACLE_HOME of local host which will run sqlplus command to connect target db using tnsname.
#            "-t TNS_NAME": specify tnsname which exists in tnsname configuration file for connect to target database.
#    "-f SIGNATURE_FOLDER": control Gen_redo.sh keep running or stop, create this folder before run Gen_redo.sh.
#          "-p SLEEP_TIME": specify sleep time for each database transaction, default is 1 second.
#       "-b CREATE_TABLES": how many tables will be create,default is 500.
#                     "-i": skip to ask db user "sys" password when sys password not default.
#    "-o OUTPUT_FILE_NAME": specify a filename which Gen_redo.sh will write all output to.
#                     "-v": print Gen_redo.sh version number.
#      "-r RUN_IN_SECONDS": how long time Gen_redo.sh will run, default 1800 seconds.
#                           (work with -f option,check that folder timestamp and current timestamp,
#                           if great than RUN_IN_SECONDS, stop Gen_Redo.sh).

version=1.9

PERL_PATH=/usr/bin
timestamp="eval date +%Y-%m-%d:%H:%M:%S"
l1="ERROR"
l2="WARNING"
l3="MESSAGE"

# function for remove single directory.
RemoveDir() {
  if [ -d "$1" ]; then
    rm -rf $1
    if [ "$?" = "0" ]; then
      printf "%s: %s: Remove %s succeed!\n" `$timestamp` $l3 $1 |tee -a $oo
    else
      printf "%s: %s: Remove %s failed!\n" `$timestamp` $l1 $1 |tee -a $oo
    fi
  else
    printf "%s: %s: Specified directory '%s' doesn't exist!\n" `$timestamp` $l2 $1 |tee -a $oo
  fi
}

PROGNAME=`basename $0`

# print usage.
PrtUsg() {
echo ""
cat <<EOF
usage: $PROGNAME options
-s ORACLE_SID         specify a instance name which you will run Gen_redo.sh on.
-h ORACLE_HOME        specify ORACLE_HOME of local host which will run sqlplus command to connect target db using tnsname.
-t TNS_NAME           specify tnsname which exists in tnsname configuration file for connect to target database.
-f SIGNATURE_FOLDER   control Gen_redo.sh keep running or stop, create this folder before run Gen_redo.sh.
-p SLEEP_TIME         specify sleep time for each database transaction, default is 1 second.
-b CREATE_TABLES      how many tables will be create,default is 500.
-i                    skip to ask db user "sys" password when sys password not default.
-o OUTPUT_FILE_NAME   specify a filename which Gen_redo.sh will write all output to.
-v                    print Gen_redo.sh version number.
-r RUN_IN_SECONDS     how long time Gen_redo.sh will run, default 1800 seconds.
                      (work with -f option,check that folder timestamp and current timestamp,
                      if great than RUN_IN_SECONDS, stop $PROGNAME).
For example: $PROGNAME -s db52 -h /opt/ora112/product/11.2.0.1/db_1 -t 10152DB52
                         -f /tmp/s.run -p 1 -b 500i -o /tmp/a.logs -i
EOF
exit 1;
}

# match options for function "getopts"
optslist="s:h:t:o:f:p:b:ir:v"

if [ "$#" -lt "1" ]; then
  PrtUsg
fi

# handle input options
while getopts $optslist opt;
do
case $opt in
  s)
    so=$OPTARG
    ;;
  h)
    ho=$OPTARG
    ;;
  t)
    to=$OPTARG
    ;;
  f)
    fo=$OPTARG
    ;;
  p)
    po=$OPTARG
    ;;
  b)
    bo=$OPTARG
    ;;
  o)
    oo=$OPTARG
    ;;
  i)
    io=yes
    ;;
  r)
    ro=$OPTARG
    ;;
  v)
    echo "$PROGNAME version: " ${version}
    exit 0;
    ;;
  ?|*)
    PrtUsg
    ;;
esac
done

# clean the old message of output file for each run
if [ -f "$oo" ]; then
  echo >$oo
fi


# set oracle environment

SetEnv() {
  ORACLE_HOME=$1
  export ORACLE_HOME
  ORACLE_SID=$2
  export ORACLE_SID
  LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/lib64
  export LD_LIBRARY_PATH
}

if [ -z "$so" ]; then
  printf "%s: %s: ORACLE_SID option missing, please set '-s ORACLE_SID'.\n" `$timestamp` $l1 |tee -a $oo
  PrtUsg
elif [ -z "$ho" ]; then
  printf "%s: %s: ORACLE_HOME option missing, please set '-h ORACLE_HOME'.\n" `$timestamp` $l1 |tee -a $oo
  PrtUsg
elif [ -z "$to" ]; then
  printf "%s: %s: TNS_NAME option missing, try to connect to local database using instance_name.\n" `$timestamp` $l3 |tee -a $oo
  cto=""
elif [ -n "$to" ]; then
  printf "%s: %s: TNS_NAME option specified, try to connect using tnsname.\n" `$timestamp` $l3 |tee -a $oo
  cto="@$to"
fi

if [ -z "$fo" ]; then
  printf "%s: %s: SIGNATURE_FILE option missing, using the default value '/tmp/s.run'.\n" `$timestamp` $l3 |tee -a $oo
  fo=/tmp/s.run
fi

if [ -z "$po" ]; then
  printf "%s: %s: SLEEP_TIME option missing, using the default value 0.\n" `$timestamp` $l3 |tee -a $oo
  po=0
fi

if [ -z "$bo" ]; then
  printf "%s: %s: CREATE_TABLES option missing, using the default value 500.\n" `$timestamp` $l3 |tee -a $oo
  bo=500
fi

if [ -z "$io" ]; then
  printf "%s: %s: '-i' didn't specified, will ask sys's password if not default.\n" `$timestamp` $l3 |tee -a $oo
  io=no
fi

if [ -z "$ro" ]; then
  printf "%s: %s: RUN_IN_TIME option missing, using the default value 1800s.\n" `$timestamp` $l3 |tee -a $oo
  ro=1800
fi

if [ ! -d $fo ]; then
  printf "%s: %s: signature folder doesn't exist, Stop to execute redo generator!\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

syspwd=oracle
ORACLE_SID=$so
export ORACLE_SID
ORACLE_HOME=$ho
export ORACLE_HOME
PATH=$PATH:$ORACLE_HOME/bin
export PATH

# check specified ORACLE_HOME/sqlplus if exist
if [ ! -f $ORACLE_HOME/bin/sqlplus ]; then
  printf "%s: %s: Specified ORACLE_HOME doesn't exit!\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

# check specified tnsname if exist
if [ -f $ORACLE_HOME/network/admin/tnsnames.ora ]; then
  checktnsnamenp=`cat $ORACLE_HOME/network/admin/tnsnames.ora|grep $to'='`
  checktnsnamewp=`cat $ORACLE_HOME/network/admin/tnsnames.ora|grep $to' ='`
  if [ -n "$to" ]; then
    if [ -z "$checktnsnamenp" -a -z "$checktnsnamewp" ]; then
      printf "%s: %s: Did not find any specified tnsname in default tnsname.ora.\n" `$timestamp` $l1 |tee -a $oo
      exit 1;
    fi
  fi
fi

# check database connection string
SetEnv $ORACLE_HOME $ORACLE_SID
result=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
exit;
EOF
`
# regards "-i" option, then execute sys password check
if [ -z "$result" ]; then
  printf "%s: %s: Confirm sys password succeed!\n" `$timestamp` $l3 |tee -a $oo
elif [ -n "`echo ${result}|grep ORA-12514`" ]; then
  printf "%s: %s: Test connect failed, please try using 'tnsping <tnsname>' to verify.\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
elif [ -n "`echo ${result}|grep ORA-12154`" ]; then
  printf "%s: %s: Test connect failed, please try using 'tnsping <tnsname>' to verify.\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
elif [ -n "`echo ${result}|grep ORA-12505`" ]; then
  printf "%s: %s: Test connect failed, using 'sqlplus sys/passwd@<tnsname> as sysdba' to verify.\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
elif [ "$io" = "no" ]; then
  printf "%s: %s: sys password not default, please input password for sys login: \n" `$timestamp` $l3 |tee -a $oo
  inputnum=0
  while true
  do
    printf "%s: %s: sys password: " `$timestamp` $l3 |tee -a $oo
    read inputpwd
    inputnum=`expr $inputnum + 1 `
    syspwd=$inputpwd
    resultcheck=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
    exit;
EOF
`
    if [ -z "$resultcheck" ]; then
      printf "%s: %s: Test connect to target database succeed.\n" `$timestamp` $l3 |tee -a $oo
      break
    elif [ "$inputnum" -lt 4 ]; then
      printf "%s: %s: Test connect failed, please retry (%s tries remaining)" $l1 $inputnum  |tee -a $oo
      continue
    else
      printf "%s: %s: Test connect failed, please re-run this script\n" `$timestamp` $l1 |tee -a $oo
      exit 1;
    fi
  done
elif [ "$io" = "yes" ]; then
  printf "%s: %s: sys password not default, change sys assword or don't specify -i option\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

deftb=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF2
  set feedback off;
  set head off;
  set echo off;
  set termout off;
  set trimout on;
  set trimspool on;
  set verify off;
  select property_value from database_properties where property_name='DEFAULT_PERMANENT_TABLESPACE';
  exit;
EOF2
`
if [ -z "$deftb" ]; then
  printf "%s: %s: Can not find any default tablespace!\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
else
  printf "%s: %s: default tablespace is: %s\n" `$timestamp` $l3 $deftb |tee -a $oo
fi

TotalTables=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
  set feedback off;
  set head off;
  set echo off;
  set termout off;
  set trimout on;
  set trimspool on;
  set verify off;
  SELECT count(table_name) FROM sys.all_tables WHERE owner='LONGEVITYUSER';
  exit;
EOF
`

DropTables_F() {
  DropTables=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
    set feedback off;
    set head off;
    set echo off;
    set termout off;
    set trimout on;
    set trimspool on;
    set verify off;
    set serveroutput on;
    @$ORACLE_HOME/rdbms/admin/dbmsrand.sql
    declare
      num0 number;
      num1 number;
      t_sqlstring VARCHAR2(500);
      d_sqlstring VARCHAR2(500);
    begin
      select count(1) into num0 from dba_users where username='LONGEVITYUSER';
      select count(1) into num1 from v\\$session where username='LONGEVITYUSER';
        if num1>0 then
          dbms_output.put_line('Gen_redo.sh running with db user longevityuser.');
          return;
        else
          if num0>0 then
            FOR rec IN (SELECT table_name FROM sys.all_tables WHERE owner='LONGEVITYUSER')
            LOOP
              t_sqlstring := 'truncate TABLE longevityuser.'||rec.table_name;
              --dbms_output.put_line(t_sqlstring);
              EXECUTE IMMEDIATE t_sqlstring;
              d_sqlstring := 'drop TABLE longevityuser.'||rec.table_name;
              EXECUTE IMMEDIATE d_sqlstring;
            END LOOP;
          end if;
        end if;
    end;
    /
    exit;
EOF
`
  return $DropTables;
}

if [ "$TotalTables" -eq "0" ]; then
  printf "%s: %s: No any tables exists under old user, drop old user directly.\n" `$timestamp` $l3 |tee -a $oo
else
  printf "%s: %s: Totally %s tables need to be truncate and drop, that will take for while...\n" `$timestamp` $l3 $TotalTables |tee -a $oo
  DropTables_F &
  DropTables_id=$!
  printf "%s: %s: Drop table process id %s.\n" `$timestamp` $l3 $DropTables_id |tee -a $oo
fi

while true
do
  LeftTotalTables=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
    set feedback off;
    set head off;
    set echo off;
    set termout off;
    set trimout on;
    set trimspool on;
    set verify off;
    SELECT count(table_name) FROM sys.all_tables WHERE owner='LONGEVITYUSER';
    exit;
EOF
`
  if [ "$LeftTotalTables" -eq "0" ]; then
    break;
  else
    printf "%s: %s: Left %s tables need drop,please waitting...\n" `$timestamp` $l3 $LeftTotalTables |tee -a $oo
    sleep 5
    continue;
  fi
done

if [ -z "$DropTables" ]; then
  printf "%s: %s: Drop tables which under old user succeed, try to drop user,should be done in 20 seconds...\n" `$timestamp` $l3 |tee -a $oo
  ChkDbUser=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
    set feedback off;
    set head off;
    set echo off;
    set termout off;
    set trimout on;
    set trimspool on;
    set verify off;
    set serveroutput on;
    begin
      execute immediate 'drop user longevityuser cascade';
    end;
    /
    exit;
EOF
`
else
  printf "%s: %s: Drop tables which under old user failed, please re-run or manually drop.\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

if [ -z "$ChkDbUser" -o -n "`echo $ChkDbUser |grep ORA-01918`" ]; then
  printf "%s: %s: Drop old user succeed!, try to create new user...\n" `$timestamp` $l3 |tee -a $oo
  CrtDbUser=`$ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF
  set feedback off;
  set head off;
  set echo off;
  set termout off;
  set trimout on;
  set trimspool on;
  set verify off;
  set serveroutput on;
  create user longevityuser identified by longevityuser default tablespace $deftb;
  grant dba,connect,resource to longevityuser;
  conn longevityuser/longevityuser$cto
  exit;
EOF
`
  if [ -z "$CrtDbUser" ]; then
    printf "%s: %s: Create new user succeed!\n" `$timestamp` $l3 |tee -a $oo
  else
    printf "%s: %s: Create new user failed!\n" `$timestamp` $l1 |tee -a $oo
    exit 1;
  fi
else
  printf "%s: %s: Another instance of gen_redo.sh is running. Please wait for it to finish or kill it.\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

# create sample table then create tables at target database according "-b" option
ChkCrtSeqTab=`$ORACLE_HOME/bin/sqlplus -S longevityuser/longevityuser$cto <<EOF
  set feedback off;
  set headsep off;
  set head off;
  set echo off;
  set termout off;
  set trimout on;
  set trimspool on;
  set verify off;
  set term off;
  declare
    num number;
    num2 number;
  begin
    select count(1) into num from user_sequences where sequence_name='LONGEVITYUSER.TMP_ID';
      if num>0 then
        execute immediate 'drop sequence longevityuser.tmp_id';
      end if;
      execute immediate 'create sequence longevityuser.tmp_id increment by 1 start with 1 maxvalue 999999999999999 nocycle nocache';
    select count(1) into num2 from user_tables where table_name='LONGEVITYUSER.SAM_TMP';
      if num2>0 then
        execute immediate 'drop table longevityuser.sam_tmp';
      end if;
      execute immediate 'create table longevityuser.sam_tmp(addr varchar2(3000),age number,marry varchar2(10),titile varchar2(100),salary number,tele number,mobile number,friend varchar2(100),wife varchar2(100))';
end;
  /
  declare
    num number;
  begin
    for lo_n in 1..$bo
    loop
      select count(1) into num from user_tables where table_name='LONGEVITYUSER.SAM_'||lo_n;
        if num>0 then
          EXECUTE IMMEDIATE 'drop table longevityuser.sam_'||lo_n ;
        end if;
      execute immediate 'create table longevityuser.sam_'||lo_n||' as select longevityuser.tmp_id.nextval as id,addr,age,marry,titile,salary,tele,mobile,friend,wife from longevityuser.sam_tmp';
      execute immediate 'create index longevityuser.sam_idx_'||lo_n||' on longevityuser.sam_'||lo_n||'('||'id'||')';
    end loop;
  end;
  /
  exit;
EOF
`

if [ -z "$ChkCrtSeqTab" ]; then
  printf "%s: %s: Create test tables succeed!\n" `$timestamp` $l3 |tee -a $oo
  printf "%s: %s: Start to run DML on created tables......\n" `$timestamp` $l3 |tee -a $oo
else
  printf "%s: %s: Create test tables failed!\n" `$timestamp` $l1 |tee -a $oo
  exit 1;
fi

# handle date command different with linux/aix/hpux/solaris
originalfoldertmstp=`$PERL_PATH/perl -e 'print ((stat($ARGV[0]))[9],"\n");' $fo`
originalcurrenttmstp=`$PERL_PATH/perl -e 'print ((time()),"\n")'`
titleonlynum=1
getredosizetimes=1

# check control folder timestamp, if {current timestamp - folder timestamp} > {"-r" option}, then stop Gen_redo.sh
while :
do
  if [ ! -d $fo ]; then
    printf "%s: %s: signature folder doesn't exist, Stop to execute redo generator!\n" `$timestamp` $l1 |tee -a $oo
    exit 1;
  fi

  foldertmstp=`$PERL_PATH/perl -e 'print ((stat($ARGV[0]))[9],"\n");' $fo`
  currenttmstp=`$PERL_PATH/perl -e 'print ((time()),"\n")'`

  if [ "$currenttmstp" -gt "$foldertmstp" ]; then
    difftmstp=`expr $currenttmstp - $foldertmstp`
    remainingtime=`expr $ro - $difftmstp`
  fi

  if [ "$difftmstp" -lt "$ro" ]; then
    if [ "$getredosizetimes" = "1" ]; then
      redo_last=`$ORACLE_HOME/bin/sqlplus -S longevityuser/longevityuser$cto <<EOF
        set feedback off;
        set head off;
        set echo off;
        set termout off;
        set trimout on;
        set trimspool on;
        set verify off;
        select to_char(trunc(value)) from v\\$sysstat where name='redo size';
        exit;
EOF
`
        getredosizetimes=`expr $getredosizetimes + 1`
    fi

    date_start=$currenttmstp

    ChkExtDML=`$ORACLE_HOME/bin/sqlplus -S longevityuser/longevityuser$cto <<EOF
      set feedback off;
      set head off;
      set echo off;
      set termout off;
      set trimout on;
      set trimspool on;
      set verify off;
      declare
        ntl number;
      begin
        if $po>0 then
          dbms_lock.sleep($po);
        end if;
        for i in 1..$bo
          loop
            select tmp_id.nextval into ntl from dual;
            execute immediate 'insert into longevityuser.sam_'||i||' values(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)' using ntl,'guangzhou',ntl,'y','ENG',ntl,ntl,ntl,'Gill','LiJing' ;
            execute immediate 'insert into longevityuser.sam_'||i||' values(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)' using ntl,'guangzhou',ntl,'y','ENG',ntl,ntl,ntl,'Gill','LiJing' ;
            execute immediate 'update longevityuser.sam_'||i||' set addr=:1,titile=:2 where id=:3' using 'shanghai','Manager',ntl ;
            execute immediate 'delete from longevityuser.sam_'||i||' where rownum<2' ;
            commit;
          end loop;
        end;
        /
      exit;
EOF
`
    date_end=`$PERL_PATH/perl -e 'print ((time()),"\n")'`
    cons_time=`expr "$date_end" - "$date_start"`

    if [ "$cons_time" -gt "0" ]; then
      tsps=`expr "$bo" / "$cons_time"`
    fi

    # force oracle write redo cache to redolog file
    $ORACLE_HOME/bin/sqlplus -S sys/$syspwd$cto as sysdba <<EOF1
      set feedback off;
      set head off;
      set echo off;
      set termout off;
      set trimout on;
      set trimspool on;
      set verify off;
      alter system checkpoint;
      exit;
EOF1

    # wait checkpoint finish
    sleep 1

    redo_stop=`$ORACLE_HOME/bin/sqlplus -S longevityuser/longevityuser$cto <<EOF
      set feedback off;
      set head off;
      set echo off;
      set termout off;
      set trimout on;
      set trimspool on;
      set verify off;
      select to_char(trunc(value)) from v\\$sysstat where name='redo size';
      exit;
EOF
  `
    if [ $redo_stop -gt $redo_last ]; then
      totally_redo=`expr $redo_stop - $redo_last`
      M_redo=`expr $totally_redo / 1024`
      redo_last=$redo_stop
    else
      printf "%s: %s: Redo log size wrong, execute DML failed\n" `$timestamp` $l1 |tee -a $oo
    fi


    if [ -z "$ChkExtDML" ]; then
      if [ "$titleonlynum" = "1" ]; then
          printf "%s: %s:        Executiontime(sec)\tTPS       \tRedo generated(bytes)\tRemaining time(sec)\n" `$timestamp` $l3 |tee -a $oo
          printf "%s: %s: Result %-17s\t%-10s\t%-21s\t%-20s\n" `$timestamp` $l3 $cons_time $tsps $M_redo $remainingtime |tee -a $oo
          titleonlynum=`expr $titleonlynum + 1`
      else
          printf "%s: %s: Result %-17s\t%-10s\t%-21s\t%-20s\n" `$timestamp` $l3 $cons_time $tsps $M_redo $remainingtime |tee -a $oo
          titleonlynum=`expr $titleonlynum + 1`
      fi
    else
      printf "%s: %s: Something wrong, detail error message is: %s\n" `$timestamp` $l1 $ChkExtDML |tee -a $oo
      RemoveDir $fo
      exit 1;
    fi
  else
    printf "%s: %s: Completed specified runtime successfully, total runtime was $ro seconds.\n" `$timestamp` $l3 |tee -a $oo
    RemoveDir $fo
    exit 0;
  fi
done
