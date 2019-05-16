#!/bin/bash

DATE=$(date +%Y-%m-%d-%H%M%S)
echo "" && echo "" && echo "" && echo "" && echo ""
echo "$DATE"
#

STATICSPEEDBASE16="0x0f"

CPUavgTupper="45"
NICTupper="65"
CPUavgTlower="40"
NICTlower="60"

CPUavgT=0
ncpu=$( sysctl hw.ncpu | awk '{ print $2 }' )

for c in `jot ${ncpu} 0`; do
 temp=$( sysctl dev.cpu.${c}.temperature | sed -e 's|.*: \([0-9.]*\)C|\1|' )
 CPUavgT=$( echo "${CPUavgT} + ${temp}" | bc )
done
	
CPUavgT=$( echo "${CPUavgT} / (${ncpu})" | bc )
echo "CPU temperature (average across all cores) is" ${CPUavgT} "C"


NICT=$(sysctl dev.t5nex.0.temperature|cut -f2 -d" ")
echo "NIC temperature is" ${NICT} "C"


#
if [[ $CPUavgT > $NICTupper || $NICT > $NICTupper ]]
  then
    echo "--> enable dynamic fan control"
    ipmitool raw 0x30 0x30 0x01 0x01
  else
  if [[ $CPUavgT < $NICTlower || $NICT < $NICTlower ]]
  then
    echo "--> disable dynamic fan control"
    ipmitool raw 0x30 0x30 0x01 0x00
    echo "--> set static fan speed"
    ipmitool raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
    fi
fi
