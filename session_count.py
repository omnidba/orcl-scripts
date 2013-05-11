#!/usr/bin/env python
#
#
#
#

import os
import os.path
import shutil
import stat
import subprocess
import tempfile

from time import strftime, localtime

try:
    import subprocess
    is_subprocess_available = True
except ImportError:
    is_subprocess_available = False

ORACLE_HOME = '/u03/app/ora11202/product/11.2.0/dbhome_1'
ORACLE_SID = 'db11202'
SQLPLUS = os.path.join(ORACLE_HOME, 'bin', 'sqlplus')
QUERY_HEADER = 'set linesize 9000\nset pagesize 9999\nset newpage none\nset feedback off\nset verify off\nset echo off\nset heading off\n'
QUERY_END = '\nquit;'

def exec_cmd(cmd):
    if is_subprocess_available:
        output = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE).communicate()[0]
    else:
        output = os.popen(cmd, 'r').read()
    return output

def run_sql(query):
    os.putenv('ORACLE_SID', ORACLE_SID)
    os.putenv('ORACLE_HOME', ORACLE_HOME)
    # try to catch OSError and propagate it to to higher handler
    try:
        temp_dir = tempfile.mkdtemp()
    except OSError:
        raise

    # add read and execute permissions for others
    mode = os.stat(temp_dir).st_mode
    os.chmod(temp_dir, mode | stat.S_IROTH | stat.S_IXOTH)

    sql_filename = os.path.join(temp_dir, '%s.sql' % os.getpid())
    sql_file = open(sql_filename, 'w+b')

    try:
        sql_file.write(QUERY_HEADER)
        sql_file.write(query)
        sql_file.write(QUERY_END)
    finally:
        sql_file.close()

    sqlplus_cmd = SQLPLUS + ' -s \"' + '/ as sysdba' + '\"' + ' @' + sql_file.name

    output = exec_cmd(sqlplus_cmd)

    shutil.rmtree(temp_dir)
    return output

def test():
    session_count = run_sql('select count(*) from v$session;')
    print strftime("%Y-%m-%d %H:%M:%S", localtime()), '[%s] SESSION_COUNT: %s' % (ORACLE_SID, session_count)

if __name__ == '__main__':
    test()
