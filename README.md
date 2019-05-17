**diskfailLED.sh**

Scan a pool, blink LEDs to locate bad disks, unblink for good ones. 

First try something like `Sessutil locate da1 on` and make sure it's blinking the right LED. Then edit `Backplane=/dev/ses0` to your backplane address and put the script into cron to run every minute or so.

Note that the script would only attempt to turn off LEDs of good drives. So the LED will keep blinking if the bad drive is removed and slot left empty. In this case put the replacement drive into the slot or use `sesutil locate all off` to turn off all LEDs.
