**diskfailLED.sh**

Scan a pool, blink LEDs to locate bad disks, unblink for good ones. 

First try something like `sesutil locate da1 on` on your system and make sure it's blinking the right LED. Then edit `Backplane=/dev/ses0` to your backplane address and put the script into cron to run every minute or so.

Note that the script would only attempt to turn off LEDs of good drives. So the LED will keep blinking if the bad drive is removed and slot left empty. In this case put the replacement drive into the slot or use `sesutil locate all off` to turn off all LEDs.



**FanControl.sh**

Simple fan script for Dell R620, should work on all Dell 12th Gen servers.

It looks at the temperature of CPU (averaged across all cores), SLOG SSD, and NIC and compare them with pre-set values. If they are all below the lower threshold, fans will be set to a static `STATICSPEEDBASE16`(in hex format) precent of max RPM. If any of the three temperature is above the upper threshold, control will be given back to iDRAC. Otherwise fan control will be left in its current state.
