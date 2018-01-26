#!/bin/sh

DEVPATH="/sys/devices/platform/ehci-platform/usb1/1-1/1-1.2"
IDPATH="/lib/network/modem"
PING_ID="baidu.com"
cat $DEVPATH/idProduct > /dev/console
cat $DEVPATH/idVendor > /dev/console
[ -f "$DEVPATH/idVendor" ] && [ -f $DEVPATH/idProduct ] || echo "$DEVPATH does not exist or no files : idVendor or idProduct"  exit 1
vid=$(cat $DEVPATH/idVendor)
pid=$(cat $DEVPATH/idProduct)

gl_configure_modem()
{
	[ -f $IDPATH/$vid:$pid ] || echo "/lib/network/modem/$vid:$pid does not exist" return 1
	if cat /lib/network/modem/$vid:$pid | grep -q $1; then
		sed -i '/modem/,/^$/d' /etc/config/network
		echo "$1" > /dev/console
		sed -n "/$1/,/^$/p" $IDPATH/$vid:$pid | sed "/$1/d" >> /etc/config/network
		sleep 2
		ifdown modem
		ifup modem
		echo "configure modem success!"
		return 0
	else
		echo "\"$1\" cannot found in /lib/network/modem/$vid:$pid"
		return 1
	fi	
}

ping_check()
{
	echo "ping $PING_ID..."
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
	if cat $IDPATH/$vid:$pid | grep -q "$2"; then  
		sed -i "/$1/,/^$/d" $IDPATH/$vid:$pid
	fi
	echo -e "\n#$1" >> $IDPATH/$vid:$pid
        sed -n '/modem/,/^$/p' /etc/config/network >> $IDPATH/$vid:$pid
	echo "save interface success!"
	return 0
}

execute_error()
{                                   
	echo "please execute \"$0 <setif|saveif> [<telecom|mobile|unicom>]\""
	exit 1
}

case $1 in
setif)
	if [ -n "$2" ]; then
		case $2 in
		telecom|unicom|mobile)
			gl_configure_modem $2
		;;
		*)
			execute_error
		;;
		esac
	else    
		gl_configure_modem telecom
	fi
;;
saveif)
	ping_check
	if [ $? = 0 ]; then
		if [ -n $2 ]; then
			case $2 in
			telecom|unicom|mobile)
				save_interface_modem $2
			;;
			*)
				execute_error
			;;
			esac
		else    
			save_interface_modem telecom
		fi
	else 
		echo "ping error"
	fi
;;
*)
	execute_error
;;
esac
exit 0

