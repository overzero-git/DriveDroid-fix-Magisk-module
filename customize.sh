install_apk() {
  if [ "$BOOTMODE" != 'true' ]; then
    ui_print '- Skipping APK installation since not running via Magisk Manager'
    return 0
  fi

  ui_print '- Installing Drive Droid APK file...'
  pm install -r "$MODPATH/system/priv-app/com.softwarebakery.drivedroid.paid951/com.softwarebakery.drivedroid.paid951.apk" || true
}


if [ "$API" -lt '30' ]; then
  abort 'This module is for Android 11+ only'
fi

install_apk
