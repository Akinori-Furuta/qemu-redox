#!/bin/bash

my_which="$(which "$0")"
my_path="$(readlink -f "${my_which}")"
my_dir="$(dirname "${my_dir}")"
my_base="$(basename "${my_dir}")"

source "${my_dir}/start-redox.conf"
source "${my_dir}/start-redox-common.sh"

echo "$0: Type Ctrl-a h to print multiplexer help."
echo "$0: Type Ctrl-a c to switch to monitor."

SDL_VIDEO_X11_DGAMOUSE=0 qemu-system-x86_64 -d cpu_reset,guest_errors -smp ${RedoxCpus} -m ${RedoxMemMB} \
	-chardev stdio,id=debug,signal=off,mux=on,"" -serial chardev:debug -mon chardev=debug \
	-machine q35 -device ich9-intel-hda -device hda-duplex -netdev user,id=net0 \
	-device e1000,netdev=net0 -device nec-usb-xhci,id=xhci -enable-kvm -cpu host \
	-drive "file=${RedoxHdd},format=${RedoxHddFormat},index=0,media=disk" \
	"$@"
