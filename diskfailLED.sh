#!/bin/bash



if [ ! "$1" ]; then
  echo "Usage: diskfailLED.sh [pool] "
  echo "Scan a pool, activate leds of failed drives"
  exit
fi

pool="$1"
Backplane=/dev/ses0


tmpdir=/tmp/diskfailLED."$pool"
mkdir "$tmpdir"

trap 'rm -rf "$tmpdir"' INT TERM EXIT



glabel status | awk '{print "s|"$1"|"$3"\t\t\t	  |g"}' > "$tmpdir"/glabel-lookup.sed # prepare translate gptid to geoms
condition=$(/sbin/zpool status $pool | egrep -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')


if [ "${condition}" ]; then


echo >&2 "Pool" "$pool" "unhealthy, scanning for failed drive(s)."



zpool status "$pool" | awk -F'was /dev/' '{print $2}' |  sed -f /tmp/glabel-lookup.old.$pool.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/missingdisk.sed # look for drives that appended with was /dev/... (uaually offline/removed/unavail state) and write them into "$tmpdir"/missingdisk.sed

for missingdisk in $(cat "$tmpdir"/missingdisk.sed);
do
	echo >&2 $missingdisk "is missing, trying to blink LED of its last known slot."
        SESid=$(echo $missingdisk | sed -f /tmp/SESidlookup.old.$pool.sed )
	sesutil locate -u $Backplane $SESid on

done


zpool status "$pool" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|FAIL|DESTROYED)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)' '{print $1}' | sed -f "$tmpdir"/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/faileddisk.sed # look for other failed drives and write them into "$tmpdir"/faileddisk.sed


for faileddisk in $(cat "$tmpdir"/faileddisk.sed);
do
	echo >&2 $faileddisk "failed, trying to blink LED."
	sesutil locate $faileddisk on

done


else

echo "Pool" "$pool" "is healthy."


#prepare SESidlookup.old.$pool.sed and glabel-lookup.old.$pool.sed to use in the future
glabel status | awk '{print "s|"$1"|"$3"\t\t\t	  |g"}' > /tmp/glabel-lookup.old.$pool.sed # prepare translate gptid to geoms

truncate -s 0 /tmp/SESidlookup.old.$pool.sed
for das in /dev/da? /dev/da??;
 do
 sesutil map | grep -w -B2 "${das//"/dev/"}" | xargs | sed 's/,.*,/ /g' | tr -d Element | sed 's/\(.* \)\(.*\)/\2\1/g' | awk '{print "s|\\<"$1 "\\>|" $2"\t\t\t  |g"}'>> /tmp/SESidlookup.old.$pool.sed

 done






fi


echo  "Turning off LEDs of good disks."

zpool status "$pool" | grep -E "(ONLINE)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spares|state|replacing|was /dev/)" |awk -F'(ONLINE)' '{print $1}' | sed -f "$tmpdir"/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/gooddisk.sed # look for good drives and write them into "$tmpdir"/gooddisk.sed

for gooddisk in $(cat "$tmpdir"/gooddisk.sed);
do

	sesutil locate $gooddisk off #2>/dev/null




done
