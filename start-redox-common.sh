#!/bin/bash

cpu_online_path=/sys/devices/system/cpu/online
cpu_online_list=$( cat "${cpu_online_path}" )

cpus=0
for cpu_mask in ${cpu_online_list/,/ }
do
	if [[ "${cpu_mask}" == *-* ]]
	then
		cpu_range=( ${cpu_mask/-/ } )
		cpus=$(( ${cpus} + ${cpu_range[1]} - ${cpu_range[0]} + 1 ))
	else
		cpus=$(( ${cpus} + 1 ))
	fi
done

if (( ${RedoxCpus} > ${cpus} ))
then
	echo "$0: Limit number of CPUs to online CPUs. cpus=${cpus}"
	RedoxCpus=${cpus}
fi
