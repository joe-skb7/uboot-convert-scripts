#!/bin/sh

# This script needs .config files generated for all defconfigs. It's done
# by running "./gen-configs.sh all" from this repo:
# https://github.com/joe-skb7/uboot-convert-scripts
#
# See [1] and [2] for more details on boards, targets and configs structuring in
# U-Boot.
#
# [1] doc/develop/kconfig.rst
# [2] doc/arch/sandbox/sandbox.rst

set -e

gen=configs_generated
cocci=remove.cocci
c_list=

# Params
dry_run=false
list_boards=false
single_board=

print_usage() {
	echo "Usage: $0 [--dry-run] [--list-boards] [board_num]"
}

parse_params() {
	while [ $# -ne 0 ]; do
		if [ "$1" = "--help" ]; then
			print_usage
			exit 0
		elif [ "$1" = "--dry-run" ]; then
			echo "[!!] Dry run"
			dry_run=true
			shift
			continue
		elif [ "$1" = "--list-boards" \
				-o "$1" = "--list" \
				-o "$1" = "-l" ]; then
			echo "[!!] Only listing boards to process"
			list_boards=true
			shift
			continue
		elif [ ! -z "${1##*[!0-9]*}" ]; then
			echo "[!!] Only processing board #$1"
			single_board=$1
			shift
			continue
		else
			echo "Error: Invalid param $1" >&2
			print_usage $*
			exit 1
		fi
	done
}

# Get the list of all board C files containing empty board_init()
get_empty_board_inits() {
	local list=
	local list_fin=

	# Get the list of all board C files with empty board_init()
	list=$(grep -Pzrl "\bboard_init\(void\)\n{\n.*return 0;\n}\n" board/)

	# Compose the final list by leaving out not related files
	for f in $list; do
		# Filter out files containing two board_init() definitions (SPL)
		set +e
		num=$(grep '\bboard_init(void)' $f | wc -l)
		set -e
		if [ $num -gt 1 ]; then
			continue
		fi

		# Filter out files where board_init() is __weak (common/)
		set +e
		grep '\bboard_init(void)' $f | grep -q '__weak'
		res=$?
		set -e
		if [ $res -eq 0 ]; then
			continue
		fi

		list_fin="$list_fin $f"
	done

	echo $list_fin
}

# Get all defconfigs related to specified board path.
#
# $1: board dir path, in a form of "board/<vendor>/<board>/...."
# Returns: list of found defconfigs for specified board path
get_defconfigs() {
	local path=$1
	local vendor=$(echo "$path" | cut -d/ -f2-2)
	local board=$(echo "$path" | cut -d/ -f3-3)
	local list_v=
	local list_b=

	# Handle special case: board/sandbox/....
	if [ $vendor = "sandbox" ]; then
		board=$vendor
		vendor=
	fi

	cd $gen

	set +e
	if [ -n "$vendor" ]; then
		# Defconfigs matching vendor
		list_v=$(grep -l "CONFIG_SYS_VENDOR=\"$vendor\"" *)
		# Defconfigs matching both vendor AND board
		list_b=$(grep -l "CONFIG_SYS_BOARD=\"$board\"" $list_v)
	else
		# Sandbox case
		list_b=$(grep -l "CONFIG_SYS_BOARD=\"$board\"" *)
	fi
	set -e

	cd - >/dev/null
	echo $list_b
}

# ---- Entry point ----

parse_params $*

make -j32 distclean

c_list=$(get_empty_board_inits)
c_num=$(echo $c_list | wc -w)

# Handle "--list-boards" param
if [ "$list_boards" = "true" ]; then
	echo "[II] Printing $c_num boards..."
	for c in $c_list; do
		echo $c
	done
	exit 0
fi

# Iterate over C files containing empty board_init()
i=1
for c in $c_list; do
	# Handle "board_num" param
	if [ -n "$single_board" -a "$single_board" != $i ]; then
		i=$((i+1))
		continue
	fi

	# Remove board_init()
	echo
	echo "---> Removing board_init() in $c... ($i / $c_num)"
	if [ $dry_run = "false" ]; then
		spatch --sp-file $cocci $c --in-place --very-quiet >/dev/null
	fi

	# Iterate over corresponding defconfigs
	d_list=$(get_defconfigs $(dirname $c))
	d_num=$(echo $d_list | wc -w)
	j=1
	if [ -z "$d_list" ]; then
		echo "$c: NOT FOUND!"
	fi
	for d in $d_list; do
		echo
		echo "  --> Processing $d... ($j / $d_num)"

		if [ $dry_run = "true" ]; then
			j=$((j+1))
			continue
		fi

		make -j32 $d
		sed -i 's/CONFIG_BOARD_INIT=y/# CONFIG_BOARD_INIT is not set/' \
			.config
		make -j32 savedefconfig
		mv defconfig configs/$d
		make -j32 distclean

		j=$((j+1))
	done

	i=$((i+1))
done

echo "[II] Done!"
