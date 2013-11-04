#!/bin/bash

#This is an example script to move your virtual disks to different volumes
#Do this after you run 'make vminit'

#Update these to point to the volumes you wish to use on your host system
TMP_PATH='/Volumes/GMS1'
GMS_PATH='/Volumes/GMS2'
DATA_PATH='/Volumes/GMS2'

#Check these paths
if [ ! -d $TMP_PATH ]; then
  echo "*** Specified TMP_PATH does not exist: $TMP_PATH  ***"
  exit
fi
if [ ! -d $GMS_PATH ]; then
  echo "*** Specified GMS_PATH does not exist: $GMS_PATH  ***"
  exit
fi
if [ ! -d $DATA_PATH ]; then
  echo "*** Specified DATA_PATH does not exist: $DATA_PATH  ***"
  exit
fi

CWD=$(dirname $0)

echo
echo "Moving temp virtual disk and creating a symlink to it"
echo mv $CWD/../tmp-disk.vdi $TMP_PATH/
mv $CWD/../tmp-disk.vdi $TMP_PATH/
echo ln -s $TMP_PATH/tmp-disk.vdi $CWD/../tmp-disk.vdi
ln -s $TMP_PATH/tmp-disk.vdi $CWD/../tmp-disk.vdi

echo
echo "Moving GMS virtual disk and creating a symlink to it"
echo mv $CWD/../opt-gms-disk.vdi $GMS_PATH/
mv $CWD/../opt-gms-disk.vdi $GMS_PATH/
echo ln -s $GMS_PATH/opt-gms-disk.vdi $CWD/../opt-gms-disk.vdi
ln -s $GMS_PATH/opt-gms-disk.vdi $CWD/../opt-gms-disk.vdi

echo
echo "Moving data virtual disk and creating a symlink to it"
echo mv $CWD/../data-disk.vdi $DATA_PATH/
mv $CWD/../data-disk.vdi $DATA_PATH/
echo ln -s $DATA_PATH/data-disk.vdi $CWD/../data-disk.vdi
ln -s $DATA_PATH/data-disk.vdi $CWD/../data-disk.vdi

echo

