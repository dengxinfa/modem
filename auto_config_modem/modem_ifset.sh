#!/bin/sh

DEVPATH="/sys/devices/platform/ehci-platform/usb1/1-1/1-1.2"
IDPATH="/lib/network/modem"
PING_ID="baidu.com"

[ -f "$DEVPATH/idVendor" ] && [ -f $DEVPATH/idProduct ] || echo "$DEVPATH does not exist or no files : idVendor or idProduct"  exit 1
vid=$(cat $DEVPATH/idVendor)
pid=$(cat $DEVPATH/idProduct)

gl_configure_modem()
{
	[ -f $IDPATH/$vid:$pid ] || echo "/lib/network/modem/$vid:$pid does not exist" return 1
	sed -i '/modem/,/^$/d' /etc/config/network
	cat $IDPATH/$vid:$pid >> /etc/config/network
	ifdown modem
	ifup modem
	echo "configure modem success!"
	return 0
}

ping_check()
{
	echo "ping success!"
	ping -c 5 $PING_ID > $IDPATH/ping_check_file &
	sleep 5
	if cat $IDPATH/ping_check_file | grep -q "round-trip"; then
		rm $IDPATH/ping_check_file
		echo "ping success!"
	else 
		rm $IDPATH/ping_check_file 
		return 1
	fi
	return 0
}

save_interface_modem()
{
	[ -f "$DEVPATH/idVendor" ] && [ -f $DEVPATH/idProduct ] || return 1
        [ -f $IDPATH/$vid:$pid ] && return 1               
        sed -n '/modem/,/^$/p' /etc/config/network > $IDPATH/$vid:$pid
	echo "save interface success!"
	return 0
}

case $1 in
setif)
	gl_configure_modem
;;
saveif)
	ping_check
	if [ $? = 0 ]; then
		save_interface_modem
	else 
		echo "ping error"
	fi
;;
*)
	echo "$0 <setif|saveif>"
;;
esac
