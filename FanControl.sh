#!/bin/bash

DATE=$(date +%Y-%m-%d-%H%M%S)

echo "$DATE"
#

STATICSPEEDBASE16="0x19" #25% RPM

CPUavgTupper="50"
NICTupper="65"
nvmeTupper="65"
CPUavgTlower="45"
NICTlower="60"
nvmeTlower="60"

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

nvmeT=$(smartctl -a /dev/nvme0 | grep Temperature | sed 's/[^0-9]*//g')
echo "nvme SSD is" ${nvmeT} "C"


if [[ $CPUavgT > $CPUavgTupper ]] || [[ $NICT > $NICTupper ]] || [[ $nvmeT > $nvmeTupper ]]
  then
    echo "--> enable dynamic fan control"
    ipmitool raw 0x30 0x30 0x01 0x01
  else
    if [[ $CPUavgT < $CPUavgTlower ]] && [[ $NICT < $NICTlower ]] && [[ $nvmeT < $nvmeTlower ]]
      then
        echo "--> disable dynamic fan control"
        ipmitool raw 0x30 0x30 0x01 0x00
        echo "--> set static fan speed"
        ipmitool raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
    fi
fi
