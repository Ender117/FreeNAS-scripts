#!/bin/bash



if [ ! "$1" ]; then
  echo "Usage: diskfailLED.sh [pool] "
  echo "Scan a pool, activate leds of failed drives"
  exit
fi

pool="$1"



tmpdir=/tmp/diskfailLED."$pool"
if mkdir "$tmpdir" ;then
  echo "Checking pool" $pool "status"
else
  echo "Another instance is already running on the pool, exiting."
  exit
fi

trap 'rm -rf "$tmpdir"' INT TERM EXIT



glabel status | awk '{print "s|"$1"|"$3"\t\t\t	  |g"}' > "$tmpdir"/glabel-lookup.sed # prepare translate gptid to geoms
condition=$(/sbin/zpool status $pool | grep -E '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')


if [ "${condition}" ]; then


echo >&2 "Pool" "$pool" "unhealthy, scanning for failed drive(s)."



zpool status "$pool" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|FAIL|DESTROYED|REMOVED)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spare|state|replacing)" | awk -F'was /dev/' '{print $2}' |  sed -f /tmp/glabel-lookup.old.$pool.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/missingdisk # look for drives that appended with was /dev/... (uaually offline/removed/unavail state) and write them into "$tmpdir"/missingdisk

for missingdisk in $(cat "$tmpdir"/missingdisk);
do
	echo >&2 $missingdisk "is missing, trying to blink LED of its last known slot."
        SESid=$(echo $missingdisk | sed -f /tmp/SESidlookup.old.$pool.sed )
	sesutil locate -u $SESid on

done


zpool status "$pool" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|FAIL|DESTROYED|REMOVED)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spare|state|replacing|was /dev/)" |awk -F'(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)' '{print $1}' | sed -f "$tmpdir"/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/faileddisk # look for other failed drives and write them into "$tmpdir"/faileddisk


for faileddisk in $(cat "$tmpdir"/faileddisk);
do
	echo >&2 $faileddisk "failed, trying to blink LED."
	sesutil locate $faileddisk on

done


else

echo "Pool" "$pool" "is healthy."


#prepare SESidlookup.old.$pool.sed and glabel-lookup.old.$pool.sed to use with potential missing disks
glabel status | awk '{print "s|"$1"|"$3"\t\t\t	  |g"}' > /tmp/glabel-lookup.old.$pool.sed # prepare translate gptid to geoms

truncate -s 0 /tmp/SESidlookup.old.$pool.sed
for backplane in /dev/ses?;
 do

  for das in /dev/da? /dev/da??;
    do
    sesutil map -u $backplane | grep -w -B2 "${das//"/dev/"}" | xargs | sed 's/,.*//' | tr -d Element | sed "s|^|${das//"/dev/"}|" |sed "s; ; $backplane ;"| awk '{print "s|\\<"$1 "\\>|" $2 " " $3"\t\t\t  |g"}'>> /tmp/SESidlookup.old.$pool.sed

  done

done




fi


echo  "Turning off LEDs of good disks."

zpool status "$pool" | grep -E "(ONLINE)" | grep -vE "($pool|NAME|mirror|raidz|stripe|logs|spare|state|replacing|was /dev/)" |awk -F'(ONLINE)' '{print $1}' | sed -f "$tmpdir"/glabel-lookup.sed | awk -F'p[0-9]' '{print $1}' | awk 'NF' >> "$tmpdir"/gooddisk # look for good drives and write them into "$tmpdir"/gooddisk

for gooddisk in $(cat "$tmpdir"/gooddisk);
do

	sesutil locate $gooddisk off #2>/dev/null
done
