#!/usr/bin/ksh

while true
do
  if find /home/tta/archivelogs/ -maxdepth 0 -empty | read
  then
    echo "empty"
  else
    echo "not empty"
    mv /home/tta/archivelogs/* /home/tta/temp/ >/dev/null 2>&1
  fi
  sleep 1
done
