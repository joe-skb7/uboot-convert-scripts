#!/bin/sh

print_usage() {
	echo "Look for corresponding header in include/configs/ for"
	echo "specified defconfig"
	echo
	echo "Usage: $0 defconfig"
	echo
	echo "Parameters:"
	echo
	echo "  defconfig - *_defconfig file from configs/"
}

if [ ! -d configs_generated ]; then
	echo "Error: Please generate configs first (using ./gen-configs.sh)" >&2
	print_usage
	exit 1
fi

if [ -z "$1" ]; then
	echo "Error: Please specify the defconfig" >&2
	print_usage
	exit 1
fi

defconfig=$1

# List all defconfig files containing found TARGET
#grep -sIrH "CONFIG_${target}=y" configs_generated/* | sed 's/:.*//g' | \
#	sed 's/configs_generated/configs/g'

target=$(grep TARGET configs_generated/$1 | grep '=y' | sed 's/=y//g' | \
	sed 's/CONFIG_//g')
if [ -z "$target" ]; then
	echo "Error: Target not found" >&2
	exit 1
fi

board_kconfig=$(grep -sIrHn $target board/ | sed 's/:.*//g')
if [ -z "$target" ]; then
	echo "Error: Board Kconfig not found" >&2
	exit 1
fi
echo "### kconfig = $board_kconfig"

configs=$(cat $board_kconfig | grep -A 1 SYS_CONFIG_NAME)
echo
echo "### configs:"
echo "$configs"

headers=$(echo "$configs" | grep default | \
	sed 's,.*default.*"\(.*\)",include/configs/\1.h,g')
echo
echo "### headers:"
echo "$headers"
