# execute SQL*Loader in a batch

export ORACLE_HOME=/opt/app/oracle/product/10.2.0.4/db_1
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=bigone
for (( i=0; i<=80000; i++ ))
do
sqlldr userid=samtest/samtest@bigone control=con$i.ctl direct=true
done
