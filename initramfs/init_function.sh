## SPDX-License-Identifier: GPL-2.0-only
## Init functions for JumpDrive
## Copyright (C) 2020 - postmarketOS
## Copyright (C) 2020 - Danctl12 <danct12@disroot.org>
## Copyright (C) 2021 - Project DragonPi
## Copyright (C) 2023 - Baonks81

setup_usb_configfs() {
	# See: https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt
	CONFIGFS=/config/usb_gadget

	if ! [ -e "$CONFIGFS" ]; then
		fatal_error "$CONFIGFS does not exist"
	fi

	# Default values for USB-related deviceinfo variables
	usb_idVendor="0x0955" # Generic
	usb_idProduct="0x7000" # Random ID
	usb_serialnumber="Tegra"
	usb_rndis_function="rndis.usb0"

	# mount as mass storage is wip so we disable it...
	#usb_mass_storage_function="mass_storage.0"

	echo "Setting up an USB gadget through configfs..."
	# Create an usb gadet configuration
	mkdir $CONFIGFS/g1 || ( fatal_error "Couldn't create $CONFIGFS/g1" )
	echo "$usb_idVendor"  > "$CONFIGFS/g1/idVendor"
	echo "$usb_idProduct" > "$CONFIGFS/g1/idProduct"

	# Create english (0x409) strings
	mkdir $CONFIGFS/g1/strings/0x409 || echo "  Couldn't create $CONFIGFS/g1/strings/0x409"

	# shellcheck disable=SC2154
	echo "$MANUFACTURER" > "$CONFIGFS/g1/strings/0x409/manufacturer"
	echo "$usb_serialnumber"        > "$CONFIGFS/g1/strings/0x409/serialnumber"
	# shellcheck disable=SC2154
	echo "$PRODUCT"         > "$CONFIGFS/g1/strings/0x409/product"

	# Create rndis function
	mkdir $CONFIGFS/g1/functions/"$usb_rndis_function" \
		|| echo "  Couldn't create $CONFIGFS/g1/functions/$usb_rndis_function"

	# Create configuration instance for the gadget
	mkdir $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1"
	mkdir $CONFIGFS/g1/configs/c.1/strings/0x409 \
		|| echo "  Couldn't create $CONFIGFS/g1/configs/c.1/strings/0x409"
	echo "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration \
		|| echo "  Couldn't write configration name"


	# Link the rndis/mass_storage instance to the configuration
	ln -s $CONFIGFS/g1/functions/"$usb_rndis_function" $CONFIGFS/g1/configs/c.1 \
		|| echo "  Couldn't symlink $usb_rndis_function"

	# Check if there's an USB Device Controller
	if [ -z "$(ls /sys/class/udc)" ]; then
		fatal_error "No USB Device Controller available"
	fi

	# shellcheck disable=SC2005
	echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC || ( fatal_error "Couldn't write to UDC" )
}

setup_telnetd() {
	echo "Starting telnet daemon..."
	{
		echo "#!/bin/sh"
		echo "echo \"Welcome to Tegra Shell!\""
		echo "sh"
	} >/telnet_connect.sh
	chmod +x /telnet_connect.sh
	telnetd -b "${IP}:23" -l /telnet_connect.sh

}

start_udhcpd() {
	# Only run once
	[ -e /etc/udhcpd.conf ] && return

	# Get usb interface
	INTERFACE=""
	ifconfig rndis0 "$IP" 2>/dev/null && INTERFACE=rndis0
	if [ -z $INTERFACE ]; then
		ifconfig usb0 "$IP" 2>/dev/null && INTERFACE=usb0
	fi
	if [ -z $INTERFACE ]; then
		ifconfig eth0 "$IP" 2>/dev/null && INTERFACE=eth0
	fi

	if [ -z $INTERFACE ]; then
		echo "Could not find an interface to run a DHCP server on, this is not good."
		echo "Interfaces:"
		ip link
		return
	fi

	echo "Network interface $INTERFACE is used"

	# Create /etc/udhcpd.conf
	{
		echo "start 172.16.42.2"
		echo "end 172.16.42.2"
		echo "auto_time 0"
		echo "decline_time 0"
		echo "conflict_time 0"
		echo "lease_file /var/udhcpd.leases"
		echo "interface $INTERFACE"
		echo "option subnet 255.255.255.0"
	} >/etc/udhcpd.conf

	echo "Started udhcpd daemon for rescue purposes"
	udhcpd
}

start_serial_getty() {
	if [ -n "$SERIAL_CON" ] && [ -n "$SERIAL_BAUD" ]; then
		# Serial console isn't supposed to be quitted, so if task is finished, relaunch it.
		sh -c "while true; do getty -l /bin/sh -n $SERIAL_BAUD $SERIAL_CON linux; done" &
	else
		echo "Not setting up serial shell, SERIAL_CON and/or SERIAL_BAUD is not defined."
	fi
}

fatal_error() {
	clear

	# Move cursor into position for error message
	echo -e "\033[$ERRORLINES;0H"
	
	# Print the error message over the error splash
	echo "  $1"

	loop_forever
}

loop_forever() {
	while true; do
		sleep 1
	done
}
