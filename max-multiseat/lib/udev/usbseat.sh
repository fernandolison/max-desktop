#!/bin/bash
# takes the "seat number" as parameter $1
# the seat number is the kernel device id of the hub the seat's devices are sitting off of
# called once for every usb device that MIGHT be part of a seat, when they arrive or remove 

echo "--------------------------------------------" >> /tmp/usbseat.log
env | grep -e ^ID -e ^DEV >> /tmp/usbseat.log


if [ "$1" = "1"  ]; then
  echo "NOT make things in DISPLAY $1" >> /tmp/usbseat.log
  exit 0
fi



if [ "$ID_VENDOR_ID" = "0711" ] && [ "$ID_MODEL_ID" = "5100" ]; then
    if [ -e /dev/usbseat/$1/keyboard ] && [ -e /dev/usbseat/$1/mouse ] && [ -e /dev/usbseat/$1/display ]; then
	echo "Device $BUSNUM $DEVNUM initialized" >> /tmp/usbseat.log
    	/lib/udev/MWS300-init-tool $BUSNUM $DEVNUM >> /tmp/usbseat.log 2>&1
    	(sleep 5 && /lib/udev/usbseat.sh $1 && tree /dev/usbseat/$1 >> /tmp/usbseat.log) &
	# exit now
	exit 0
    fi
fi

if [[ !(-n `/bin/pidof gdm`) ]]; then
    exit 0
fi


seat_running=`/usr/bin/gdmdynamic -l | /bin/sed -n -e "/:$1,/p"`

# $ACTION environment variable is set by udev subsystem
case "$ACTION" in
	'remove')
		if [[ -n "{$seat_running}" ]]; then
			/usr/bin/gdmdynamic -v -d $1
		fi
		;;
	*)
                # A device which might be part of a seat has been added

		# if we already have a running seat for this #, exit
		if [[ -n "${seat_running}" ]]; then
			exit 0
		fi

		if [[ -e /dev/usbseat/$1/keyboard && -e /dev/usbseat/$1/mouse && -e /dev/usbseat/$1/display ]]; then

			# We have a newly complete seat. Start it.
			#TMPFILE=`/bin/mktemp` || exit 1
			TMPFILE=`/bin/mktemp -t usbseat.XXXXXXXXXX` || exit 1
			if lsusb | grep -q 0711:5100; then
				echo "MWS300 complete, launching GDMdynamic in $1 with $TMPFILE" >> /tmp/usbseat.log
				#/bin/sed "s/%ID_SEAT%/$1/g" < /lib/udev/usbseat-xf86.tusb.conf.sed > $TMPFILE

				VEND_ID=$(readlink -f /dev/usbseat/$1/display | awk -F"/" '{print $5}')
				PROD_ID=$(readlink -f /dev/usbseat/$1/display | awk -F"/" '{print $6}')
				/bin/sed -e "s/%ID_SEAT%/$1/g" -e "s|%VEND_ID%|$VEND_ID|g" -e "s|%PROD_ID%|$PROD_ID|g"  /lib/udev/usbseat-xf86.tusb.conf.sed > $TMPFILE
			else
				/bin/sed "s/%ID_SEAT%/$1/g" < /lib/udev/usbseat-xf86.conf.sed > $TMPFILE
			fi
			tree /dev/usbseat/$1 >> /tmp/usbseat.log

			/usr/bin/gdmdynamic -v -t 2 -s 1 -a "$1=/usr/bin/X -br :$1 vt07 -audit 0 -nolisten tcp -config $TMPFILE"
			#/usr/bin/gdmdynamic -v -t 2 -s 1 -a "$1=/usr/bin/X -br :$1 -audit 0 -nolisten tcp -novtswitch -sharevts -config $TMPFILE"

			/usr/bin/gdmdynamic -v -r $1
		else
			echo "Some devices not found" >> /tmp/usbseat.log
			tree /dev/usbseat/$1 >> /tmp/usbseat.log
		fi
		;;
esac

exit 0


