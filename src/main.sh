#!/bin/bash -x
#

SYS_PATH="/sys/devices/pci0000:00/0000:00:13.0/0000:01:00.0"
PRG_NAME=$(readlink -e ${BASH_SOURCE[0]})
ROOT_LVL=$(dirname $(dirname ${PRG_NAME}))
EEUPDATE=${ROOT_LVL}/bin/eeupdate64e
FIRMWARE=${ROOT_LVL}/i211/I211_Invm_APM_v0.4.txt
MAC_FILE=${ROOT_LVL}/mac/file

function device_80861539() {
	local mac=$(find ${SYS_PATH} | awk '/address/' )
	local net=$( basename $( dirname ${mac} ))
	mac=$(cat ${mac})
cat << eof
	The device ${SYS_PATH} is already network device.
	${net} [ ${mac} ]
eof
}

function device_80861532() {
	DEV_ID="8086-1532"
	eval $(${EEUPDATE}  /ALL | awk -v dev_id=${DEV_ID} '($0~dev_id)&&($0="bus=0x"$2"; dev=0x"$3)')
	$EEUPDATE /bus=$bus /dev=$dev /invmupdate /file=${FIRMWARE}
	$EEUPDATE /bus=$bus /dev=$dev /mac ${MAC_ADDR}

cat << eof
	Reboot the device
eof
}

eval $(awk '(/PCI_ID/&&(gsub(/:/,"")))' ${SYS_PATH}/uevent)
PCI_ID=${PCI_ID:-"empty"}

function_to_issue="device_${PCI_ID}"
command -v ${function_to_issue} || {

cat << eof
	Invalid $(  awk '/PCI_ID/' ${SYS_PATH}/uevent )
eof
exit 1
}

SN=$(dmidecode -t 2 | awk '(/Serial Number:/)&&($0=$NF)')
MAC_ADDR=$(awk -v sn=${SN} '($0~sn)&&($0=$2)' ${MAC_FILE})
[[ -n ${MAC_ADDR} ]] || {
MAC_ADDR=${SN/-/}
MAC_ADDR="0001c0${MAC_ADDR:6}"
cat << eof
	No mac for ${SN} in the ${MAC_FILE}
	Using MAC from ${SN} is ${MAC_ADDR}
eof
}

MAC_ADDR=${MAC_ADDR} SN=${SN} ${function_to_issue}
