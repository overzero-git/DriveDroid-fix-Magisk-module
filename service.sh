#!/bin/sh

# run while loop for boot_completed status & sleep 10 needed for magisk service.d
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
sleep 10

# save currently active function name
echo "$(ls -al /config/usb_gadget/g1/configs/b.1/)" | grep -Eo f1.* | awk '{print $3}' | cut -d/ -f8 > /data/adb/.fixdd

# loop
# run every 0.5 seconds
while true
do
  # check the app is active
  chkapp="$(pgrep -f drivedroid | wc -l)"
  # check currently active function
  chkfn=$(echo "$(ls -al /config/usb_gadget/g1/configs/b.1/)" | grep -Eo f1.* | awk '{print $3}' | cut -d/ -f8)
  # load previous active function
  chkfrstfn="$(cat /data/adb/.fixdd)"
  if [ "$chkapp" -eq "1" ] && [ "$chkfn" != "mass_storage.0" ]; then
    # add mass_storage.0 config & function and remove currently active function
    setprop sys.usb.config cdrom
    setprop sys.usb.configfs 1
    rm /config/usb_gadget/g1/configs/b.1/f*
    mkdir -p /config/usb_gadget/g1/functions/mass_storage.0/lun.0/
    ln -s /config/usb_gadget/g1/functions/mass_storage.0 /config/usb_gadget/g1/configs/b.1/f1
    getprop sys.usb.controller >/config/usb_gadget/g1/UDC
    setprop sys.usb.state cdrom
  elif [ "$chkapp" -eq "0" ] && [ "$chkfn" = "mass_storage.0" ]; then
    # remove mass_storage.0 function & restore previous function
    setprop sys.usb.configfs 1
    rm /config/usb_gadget/g1/configs/b.1/f*
    ln -s /config/usb_gadget/g1/functions/"$chkfrstfn" /config/usb_gadget/g1/configs/b.1/f1 
    echo a600000.dwc3 > /config/usb_gadget/g1/UDC
  if [ "$chkfrstfn" = "ffs.adb" ]; then
    setprop sys.usb.config adb
   elif [ "$chkfrstfn" = "mtp.gs0" ]; then
    setprop sys.usb.config mtp
   fi
  fi
  sleep 0.5
done
