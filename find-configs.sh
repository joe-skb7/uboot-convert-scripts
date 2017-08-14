#!/bin/sh

print_usage() {
	echo "List all defconfig files that use specified target"
	echo
	echo "Usage: $0 target"
	echo
	echo "Parameters:"
	echo
	echo "  target - target config from ./find-target.sh output"
}

if [ ! -d configs_generated ]; then
	echo "Error: Please generate configs first (using ./gen-configs.sh)" >&2
	print_usage
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "Error: Please specify the target" >&2
	print_usage
	exit 1
fi

target=$1

echo
grep -sIrH "CONFIG_${target}=y" configs_generated/* | sed 's/:.*//g' \
	| sed 's/configs_generated/configs/g'
