#!/bin/bash

my_which="$(which "$0")"
my_path="$(readlink -f "${my_which}")"
my_dir="$(dirname "${my_dir}")"
my_base="$(basename "${my_dir}")"

source "${my_dir}/start-redox.conf"
source "${my_dir}/start-redox-common.sh"

if [[ ! -e "${RedoxHdd}" ]]
then
	"${RedoxHdd}: Create virtual hard disk. size=${RedoxHddSize}"
	qemu-img create -f "${RedoxHddFormat}" "${RedoxHdd}" "${RedoxHddSize}"
fi

# arg: none
# note: pipe-line process
#  list files |
#  duplicate file_name |
#  extract date build_number file_name |
#  sort {date, build_number} in reverse order |
#  take first line |
#  extract 3rd field
function FindRedoxIso() {
	push "${my_dir}" > /dev/null

	ls redox_*.iso redox_*.iso.zst | \
	sed 's/\(^.*$\)/\1 \1/' | \
	sed 's/^[[:alpha:]]*_[[:alpha:]]*_.*_\([0-9]\+-[0-9]\+-[0-9]\+\)_\([0-9]\+\).*[[:space:]]\+\(.*\)/\1 \2 \3/' | \
	sort -s -k 1,1r --key=2,2nr | \
	head -1 | \
	cut -d ' ' -f 3

	popd > /dev/null
}

if [[ -z "${RedoxIso}" ]]
then
	RedoxIso="$( FindRedoxIso )"
	if [[ -n "${RedoxIso}" ]]
	then
		redox_find="${my_dir}/${RedoxIso}"
		redox_iso="${my_dir}/${RedoxIso%.zst}"

		if [[ ! -e "${redox_iso}" ]]
		then
			if [[ ( "${RedoxIso}" == *.zst ) && ( -f "${redox_find}" ) ]]
			then
				echo "${redox_find}: Decompress zst image file."
				unzstd "${redox_find}"
			fi
		fi
		RedoxIso="${redox_iso}"
	fi
fi

if [[ ! -e "${RedoxIso}" ]]
then
	echo "$0: Can not find Redox Desktop installer ISO image file."
	exit 2
else
	echo "${RedoxIso}: Found Redox Desktop installer ISO image."
fi

echo "$0: Type Ctrl-a h to print multiplexer help."
echo "$0: Type Ctrl-a c to switch to monitor."

SDL_VIDEO_X11_DGAMOUSE=0 qemu-system-x86_64 -d cpu_reset,guest_errors -smp ${RedoxCpus} -m ${RedoxMemMB} \
	-chardev stdio,id=debug,signal=off,mux=on,"" -serial chardev:debug -mon chardev=debug \
	-machine q35 -device ich9-intel-hda -device hda-duplex -netdev user,id=net0 \
	-device e1000,netdev=net0 -device nec-usb-xhci,id=xhci -enable-kvm -cpu host \
	-drive "file=${RedoxHdd},format=${RedoxHddFormat},index=0,media=disk" \
	-drive "file=${RedoxIso},index=1,media=cdrom" \
	"$@"
