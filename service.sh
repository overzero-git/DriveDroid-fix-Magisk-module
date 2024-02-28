#!/bin/sh

# Developed by mmtrt (https://gist.github.com/mmtrt)
# Improoved by Danil Vyazikov (https://github.com/overzero-git/) and barsikus007 (https://gist.github.com/barsikus007/)
# Published under GPLv3


# run while loop for boot_completed status & sleep 10 needed for magisk service.d
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
sleep 10

get_fn_type() {
  # get currently active function name
  if ls /config/usb_gadget/g1/configs/b.1/function* > /dev/null 2>&1
  then
    echo "function"
  else
    echo "f"
  fi
}

fn_type=$(get_fn_type)

get_chkfn() {
  # get currently active function name
  ls -al /config/usb_gadget/g1/configs/b.1/ | grep -Eo "$fn_type[0-9]+[[:space:]].*" | awk '{print $3}' | cut -d/ -f8
}

get_last_fn() {
  # get currently free function number
  num=$(ls -al /config/usb_gadget/g1/configs/b.1/ | grep -Eo "$fn_type[0-9]+[[:space:]]" | tail -1 | cut -dn -f 3)
  echo "$fn_type"$((num+1))
}

is_mass_storage_present() {
  # returns 1 if mass_storage.0 is present
  ls -al /config/usb_gadget/g1/configs/b.1/ | grep -Eo "mass_storage.0" | wc -l
}

get_mass_storage_path() {
  # get path to mass_storage.0
  ls -al /config/usb_gadget/g1/configs/b.1/ | grep -Eo "$fn_type[0-9]+[[:space:]].*mass_storage.0" | cut -d' ' -f1
}

# save currently active function name
if [ "$fn_type" = "f" ]; then
  get_chkfn > /data/adb/.fixdd
fi

# loop
# run every 0.5 seconds
while true
do
  # check the app is active
  chkapp="$(pgrep -f drivedroid | wc -l)"
  # check if mass storage is active function
  mass_storage_active=$(is_mass_storage_present)
  if [ "$chkapp" -eq "1" ] && [ "$mass_storage_active" -eq "0" ]; then
    # add mass_storage.0 to currently active functions
    if [ "$fn_type" = "f" ]; then
      setprop sys.usb.config cdrom
      setprop sys.usb.configfs 1
      rm /config/usb_gadget/g1/configs/b.1/f*
    fi

    mkdir -p /config/usb_gadget/g1/functions/mass_storage.0/lun.0/
    ln -s /config/usb_gadget/g1/functions/mass_storage.0 "/config/usb_gadget/g1/configs/b.1/$(get_last_fn)"

    if [ "$fn_type" = "f" ]; then
      getprop sys.usb.controller > /config/usb_gadget/g1/UDC
      setprop sys.usb.state cdrom
    fi
  elif [ "$chkapp" -eq "0" ] && [ "$mass_storage_active" -eq "1" ]; then
    # remove mass_storage.0 function
    rm "/config/usb_gadget/g1/configs/b.1/$(get_mass_storage_path)"
    # it seems, that pixel 7 doesn't use sys.usb.config at all
    if [ "$fn_type" = "f" ]; then
      # reload of configfs to fix samsung android auto
      setprop sys.usb.configfs 0
	  sleep 0.5
      setprop sys.usb.configfs 1
      # load previous active function
      chkfrstfn="$(cat /data/adb/.fixdd)"
	  
      ln -s /config/usb_gadget/g1/functions/"$chkfrstfn" /config/usb_gadget/g1/configs/b.1/f1
      # Need more code cleanup & optimization here
      ls /sys/class/udc/ | grep -Eo ".*\.dwc3" > /config/usb_gadget/g1/UDC
	  setprop sys.usb.state mtp
      if [ "$chkfrstfn" = "ffs.adb" ]; then
        setprop sys.usb.config adb
      elif [ "$chkfrstfn" = "ffs.mtp" ]; then
        setprop sys.usb.config mtp
	  elif [ "$chkfrstfn" = "mtp.gs0" ]; then
        setprop sys.usb.config mtp		
      fi
    fi
  fi
  sleep 0.5
done