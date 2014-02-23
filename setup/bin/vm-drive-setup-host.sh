#!/bin/bash
[ -e "tmp-disk.vdi" ]           || (echo "*** creating tmp-disk.vdi ***"            && VBoxManage createhd --filename "tmp-disk.vdi" --size 2000000 --format VDI)
[ -e "opt-gms-disk.vdi" ]       || (echo "*** creating opt-gms-disk.vdi ***"        && VBoxManage createhd --filename "opt-gms-disk.vdi" --size 2000000 --format VDI)
[ -e "opt-gms-local-disk.vdi" ] || (echo "*** creating opt-gms-local-disk.vdi ***"  && VBoxManage createhd --filename "opt-gms-local-disk.vdi" --size 2000000 --format VDI)
