#!/bin/sh

dir=defconfigs_generated
configs=""
i=1

print_usage() {
	echo "Regenerate defconfig files with correct options order"
	echo
	echo "Usage: $0 {all | head | configs list ...}"
	echo
	echo "Parameters:"
	echo "  all  - For all defconfigs from configs/"
	echo "  head - For changed configs/ files in last commit"
	echo "  configs list - For manually specified list of config files "
	echo "                 from configs/ directory"
	echo
	echo "Generated files will be located in ${dir}/ directory"
}

if [ $# -eq 0 ]; then
	echo "Error: Invalid arguments count" >&2
	print_usage
	exit 1
fi

# Check "all" and "head" params
if [ $# -eq 1 ]; then
	if [ $1 = "all" ]; then
		configs=$(ls -1 configs/)
		shift
	elif [ $1 = "head" ]; then
		configs=$(git show --stat | grep '^ configs/' | \
			awk '{print $1}' | sed 's,^configs/,,g' | sort -u)
		shift
	fi
fi

# Check for manually provided configs list
if [ -n "$1" ]; then
	configs=$1
fi

rm -rf $dir
mkdir $dir

count=$(echo $configs | wc -w)

# Generate defconfigs
make distclean
rm -f defconfig
for c in $configs; do
	echo "---> Generating $c... ($i / $count)"
	make $c
	make savedefconfig
	mv defconfig $dir/$c
	make distclean
	i=$((i+1))
done
