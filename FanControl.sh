#!/bin/bash

DATE=$(date +%Y-%m-%d-%H%M%S)
echo "" && echo "" && echo "" && echo "" && echo ""
echo "$DATE"
#

STATICSPEEDBASE16="0x0f"
STATICSPEEDBASE16="0x0f"
TEMPTHRESHOLD="29"
#
ncpu=$( sysctl hw.ncpu | awk '{ print $2 }' )


avg=0

for c in `jot ${ncpu} 0`; do
 temp=$( sysctl dev.cpu.${c}.temperature | sed -e 's|.*: \([0-9.]*\)C|\1|' )
 avg=$( echo "${avg} + ${temp}" | bc )
done
	
avg=$( echo "${avg} / (${ncpu})" | bc )
rc=${avg}


echo "$IDRACIP: -- current temperature --"
echo "$T"
#
if [[ $T > $TEMPTHRESHOLD ]]
  then
    echo "--> enable dynamic fan control"
    ipmitool raw 0x30 0x30 0x01 0x01
  else
    echo "--> disable dynamic fan control"
    ipmitool raw 0x30 0x30 0x01 0x00
    echo "--> set static fan speed"
    ipmitool raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
fi
