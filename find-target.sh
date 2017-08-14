#!/bin/sh

print_usage() {
	echo "List all defconfig files (from configs/) that are related to "
	echo "config header specified"
	echo
	echo "Usage: $0 config_header"
	echo
	echo "Parameters:"
	echo
	echo "  config_header - .h file from include/configs/"
}

if [ ! -d configs_generated ]; then
	echo "Error: Please generate configs first (using ./gen-configs.sh)" >&2
	print_usage
	exit 1
fi

if [ -z "$1" ]; then
	echo "Error: Please specify header file name" >&2
	print_usage
	exit 1
fi

header=$1
# Cut off file extension
name='"'$(echo $header | cut -d'.' -f1)'"'

# Find related Kconfig file
kconfig=$(grep-all . $name SYS_CONFIG_NAME | grep Kconfig)
echo "### kconfig = $kconfig"

# Figure out TARGET
#target=$(cat $kconfig | grep $name | grep TARGET_ | sed 's/.*\(TARGET_.*\)/\1/g')
target=$(cat $kconfig | grep $name | grep TARGET_)
if [ -z "$target" ]; then
#	target=$(cat $kconfig | grep TARGET_ | sed 's/.*\(TARGET_.*\)/\1/g')
	target=$(cat $kconfig | grep TARGET_)
fi

echo "### targets:"
echo $target | tr " " "\n" | grep -v if
