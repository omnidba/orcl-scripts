export ORACLE_SID=$1
export ORACLE_HOME=/oracle/opt/oracle/product/10.2.0/db_1
export PATH=$ORACLE_HOME/bin:$PATH
rman target / <<EOF
delete force noprompt archivelog all completed before 'sysdate-1';
exit;
EOF
