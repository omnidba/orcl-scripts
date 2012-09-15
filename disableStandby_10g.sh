#!/bin/bash

# set ORACLE_HOME
ORACLE_HOME=/oracle/opt/oracle/product/10.2.0/db_1
export ORACLE_HOME

# set ORACLE_SID
ORACLE_SID=boston
export ORACLE_SID

# set PATH
case "$PATH" in
    *$ORACLE_HOME/bin/*) ;;
    "") PATH=$ORACLE_HOME/bin ;;
    *)  PATH=$ORACLE_HOME/bin:$PATH ;;
esac
export PATH

# set LD_LIBRARY_PATH
case "$LD_LIBRARY_PATH" in
    *$ORACLE_HOME/lib*) ;;
    "") LD_LIBRARY_PATH=$ORACLE_HOME/lib ;;
    *)  LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH ;;
esac
export LD_LIBRARY_PATH

echo "disable" >/tmp/disable.log
sqlplus / as sysdba <<EOF
alter database recover managed standby database cancel;
alter database open read only;
exit;
EOF
echo "disable done" >>/tmp/disable.log
