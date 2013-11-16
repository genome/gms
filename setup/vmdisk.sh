#!/bin/bash
[ -e "/Volumes/GMS1/tmp-disk.vdi" ]     || (echo "*** creating /Volumes/GMS1/tmp-disk.vdi ***"     && VBoxManage createhd --filename "/Volumes/GMS1/tmp-disk.vdi" --size 2000000 --format VDI)
[ -e "/Volumes/GMS2/opt-gms-disk.vdi" ] || (echo "*** creating /Volumes/GMS2/opt-gms-disk.vdi ***" && VBoxManage createhd --filename "/Volumes/GMS2/opt-gms-disk.vdi" --size 2000000 --format VDI)
