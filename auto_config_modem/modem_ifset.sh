#!/bin/sh
gl_configure_modem()
{
DEVPATH="/sys/devices/platform/ehci-platform/usb1/1-1/1-1.2"
[ -f "$DEVPATH/idVendor" ] && [ -f $DEVPATH/idProduct ] || echo "$DEVPATH does not exist or no files : idVendor or idProduct"  exit 0
vid=$(cat $DEVPATH/idVendor)
pid=$(cat $DEVPATH/idProduct)
[ -f "/lib/network/modem/$vid:$pid" ] || echo "/lib/network/modem/$vid:$pid does not exist" exit 0
sed -i '/modem/,/^$/d' /etc/config/network
cat /lib/network/modem/$vid:$pid >> /etc/config/network
ifdown modem
ifup modem
echo "configure modem success!"
}

gl_configure_modem

