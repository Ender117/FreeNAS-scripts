#!/bin/bash
if [ ! "$1" ]; then
echo "Usage: diskfailLED.sh [pool1] [pool2] [pool3] ..."
echo "Scan the specified pool(s), activate leds of failed drives, turn off for good ones"
exit
fi

echo "Checking" $# "pool(s)"

allpool="$*"

globalcondition=$(/sbin/zpool status "$allpool" | grep -iE '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)') # check if all pools are healthy

if [ "${globalcondition}" ]; then
glabel status | awk '{print "s|"$1"|"$3"\t\t\t      |g"}' > /tmp/glabel-lookup.sed # prepare translate gptid to geoms 
echo "$allpool"|tr " " "\n" > /tmp/poolstoscan.sed  # write pools to scan each in a line into /tmp/poolstoscan.sed 

#if [ ! -f /tmp/diskfailureledon ]; then
#else
#sesutil locate all off > /dev/null 2>&1
#fi


for pool in $(cat /tmp/poolstoscan.sed);
do

condition=$(/sbin/zpool status "$pool" | grep -iE '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')# check if pool is healthy

if [ "${condition}" ]; then

echo "$pool" "is unhealthy, scanning for failed drive(s)."

zpool status "$pool" | awk -F'was /dev/' '{print $2}' |  sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/faileddisk.sed # look for drives that appended with was /dev/... (uaually offline/removed/unavail state) and write them into /tmp/faileddisk.sed
zpool status "$pool" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)' '{print $1}' | sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/faileddisk.sed # look for other failed drives and write them into /tmp/faileddisk.sed
zpool status "$pool" | grep -E "(ONLINE)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(ONLINE)' '{print $1}' | sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/gooddisk.sed # look for good drives and write them into /tmp/gooddisk.sed


for faileddisk in $(cat /tmp/faileddisk.sed);
do
echo "$faileddisk" "failed, trying to blink LED."
sesutil locate "$faileddisk" on # blink LED for every drives in /tmp/faileddisk.sed
touch /tmp/diskfailureledon #so that next run knows LED was turned on by this script
done
rm /tmp/faileddisk.sed


for gooddisk in $(cat /tmp/gooddisk.sed);
do
echo "$gooddisk" "is healthy, trying turn off LED."
sesutil locate "$gooddisk" off # turn off LED for every drives in /tmp/gooddisk.sed
done
rm /tmp/gooddisk.sed

else

echo "$pool" "is healthy, turning off LEDs."
zpool status "$pool" | grep -E "(ONLINE)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(ONLINE)' '{print $1}' | sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/gooddisk.sed # look for good drives and write them into /tmp/gooddisk.sed
for gooddisk in $(cat /tmp/gooddisk.sed);
do
echo "$gooddisk" "is healthy, trying turn off LED."
sesutil locate "$gooddisk" off # turn off LED for every drives in /tmp/gooddisk.sed
done
rm /tmp/gooddisk.sed

fi

done

rm /tmp/glabel-lookup.sed
rm /tmp/poolstoscan.sed

else


if [ ! -f /tmp/diskfailureledon ]; then #check if /tmp/diskfailureledon exists because "sesutil locate all off" is slow
echo "All pool(s) are healthy, exiting."
else
echo "All pool(s) are healthy, turning off all LEDs."
sesutil locate all off > /dev/null 2>&1
rm /tmp/diskfailureledon
fi



fi	




