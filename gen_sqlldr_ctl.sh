# generate SQL*Loader control file

for (( i=1; i<=80000; i++ ))
do
echo "LOAD   DATA
  INFILE   '/home/ora1024/sam_work/txt.txt'
  APPEND INTO   TABLE   SAM_$i
  FIELDS   TERMINATED   BY   ','
(ID,ADDR,AGE,MARRY,TITILE,SALARY,TELE,MOBILE,FRIEND,WIFE) ">con$i.ctl
done
