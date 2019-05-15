#!/bin/bash
if [ ! "$1" ]; then
  echo "Usage: diskfailLED.sh [pool] "
  echo "Scan a pool, activate leds of failed drives"
  exit
fi
pool="$1"

condition=$(/sbin/zpool status $pool | egrep -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')

if [ "${condition}" ]; then


echo "$pool" "unhealthy, scanning for failed drive(s)."

glabel status | awk '{print "s|"$1"|"$3"\t\t\t	  |g"}' > /tmp/glabel-lookup.sed # prepare translate gptid to geoms

zpool status $pool | grep -vE "(REMOVED|$pool)" | awk -F'was /dev/' '{print $2}' |  sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/faileddisk.sed

zpool status $pool | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|was /dev/)" |awk -F'(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)' '{print $1}' |  sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/faileddisk.sed



#sesutil locate all off > /dev/null 2>&1

for faileddisk in $(cat /tmp/faileddisk.sed);
do
	echo $faileddisk "failed, trying to blink LED."
	sesutil locate $faileddisk on

done



else

echo "$pool" "is healthy."
#sesutil locate all off > /dev/null 2>&1


fi


echo  "Turning off LEDs of good disks."
zpool status "$pool" | grep -E "(ONLINE)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(ONLINE)' '{print $1}' | sed -f /tmp/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> /tmp/gooddisk.sed # look for good drives and write them into /tmp/gooddisk.sed
for gooddisk in $(cat /tmp/gooddisk.sed);
do

	sesutil locate $gooddisk off

done



rm /tmp/glabel-lookup.sed
rm /tmp/faileddisk.sed
rm /tmp/gooddisk.sed
