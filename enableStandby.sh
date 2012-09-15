#!/bin/bash

# set ORACLE_HOME
ORACLE_HOME=/opt/oracle/product/11.2.0/dbhome_1
export ORACLE_HOME

# set ORACLE_SID
ORACLE_SID=pds100p
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

echo "enable" >/tmp/enable.log
sqlplus / as sysdba <<EOF
alter database recover managed standby database using current logfile disconnect;
exit;
EOF
echo "enable done" >>/tmp/enable.log
