#!/bin/bash

# i3statush - A modular status bar for i3 written in BASH 
#
# Copyright (C) 2016 Yann Privé, Boris Ntfd
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.

source ~/.i3/i3status.conf

# Main function
main() {
	# Local variables
	local i3_vol=' INIT'
	local i3_date=' INIT'
	local i3_cpu='CPU: INIT'
	local i3_ram='RAM: INIT'
	local i3_temp=""
	local rx_info='0: INIT'
	local tx_info='0: INIT'
	local net="_get_net"
	local sound="_get_volume"
	local temp="_get_temp"
	local battery="_get_battery"
	local cpu="_get_cpu"
	local ram="_get_ram"
	local loadavg="_get_loadavg"
	local date="_get_date"

	# Infinite loop
	while true; do
		# Switch on the seconds value
		case "$(date '+%S')" in
			# Called every 2 seconds : [0-5][02468])
			# Called every 5 seconds : [0-5][05])

			# Called every second
			*)

			i3_date=$(_get_date)

			# Gets the network usage
			rx_info=$(_get_net_info 'rx' "${rx_info%:*}" "$INTERFACE_WIFI")
			tx_info=$(_get_net_info 'tx' "${tx_info%:*}" "$INTERFACE_WIFI")
			;;&

		esac

		# Echo the statusbar line
		echo "${rx_info#*:} - ${tx_info#*:} $SEP $(_get_volume) $SEP $(_get_temp) $SEP	$(_get_battery) $SEP $(_get_cpu) - $(_get_ram) - $(_get_loadavg) $SEP  ${i3_date}"

		#for feature in ${MYBAR[*]}; do
		 #	 eval $feature
		#done

		# Sleep 1 second
		sleep 1

	done

	return 0
}

_get_ram(){
	awk '{
			a[i++]=$2
		}END{
			printf "RAM: %d/%dMB (%.2f%%)\n", a[1]/1024, a[0]/1024, a[1]*100/a[0]
		}' <(grep -Pe "MemTotal|MemFree" /proc/meminfo)
}

_get_cpu(){
	awk '/cpu /{
		cpu=($2+$4)*100/($2+$4+$5)
		} END {
			printf "CPU: %.4s%", cpu
		}' /proc/stat
}

_get_battery(){
	#   
	# 
	local BATTERY=$(awk -F'[ ,]' '/Battery 0/{if(!a[$0]++){print $3, $5, $7}}' <<< "$(acpi -V)" |head -n1)
	[[ "$BATTERY" =~ Discharging.([[:digit:]]+%).(.*$) ]] \
		&& echo " ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}" \
		|| {
					[[ -z ${BASH_REMATCH} ]] \
						&& echo "	$BATTERY" \
						|| echo "	${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
				}
}

_get_loadavg(){
	# 
	local LOADAVG=($(awk '{print $1, $2, $3}' /proc/loadavg))
	local RET
	for VAL in "${LOADAVG[@]}"; do
		if awk '{exit $1>$2?0:1}' <<< "$VAL ${ALERTLOADAVG}"; then
			RET+="$R$VAL$N "
		elif awk '{exit $1<$2?0:1}'<<< "$VAL ${WARNINGLOADAVG}"; then
			RET+="$G$VAL$N "
		else RET+="$Y$VAL$N "
		fi
	done
	echo -e "	$RET"
}

# Gets the current volume
_get_volume() {

	# Local variables
	local amixer_vol vol_string amixer_status

	# Call amixer to get the current volume
	amixer_vol=$(amixer get Master | grep -m 1 -Eo '[0-9]+%')
	amixer_status=$(amixer get Master | awk -F'[][]' '/Front Left.*Play/{print $4}')
	amixer_vol=${amixer_vol::-1}

	# Use the right icon
	[[ "$amixer_status" == "on" ]] && {
		if [[ "$amixer_vol" -eq 0 ]]
	   then
		   vol_string=" 0%"

	   elif [[ "$amixer_vol" -gt 0 && "$amixer_vol" -le 50 ]]
	   then
		   vol_string=$(printf ' %3s%%' "${amixer_vol}")

	   else
		   vol_string=$(printf ' %3s%%' "${amixer_vol}")
	   fi
   } || { amixer_status="	${Y}Muted$N" ; }

	# Echoes the volume
	echo -e "${vol_string:-$amixer_status}"

	return 0
}

# Gets the current date
_get_date() {

	# Return the date
	echo -n "	$(date '+%d/%m/%y') "
	echo "  $(date '+%T')"

	return 0
}

# Gets the network information
_get_net_info() {

	# Local variables
	local link_way=$1
	local link_bytes_prev=$2
	local device=$3
	local link_bytes_cur
	local link_speed
	local link_string

	# Get the number of bytes sent / received & gets the speed
	link_bytes_cur=$(</sys/class/net/${device}/statistics/${link_way}_bytes)
	link_speed=$(((link_bytes_cur - link_bytes_prev) * 8))

	# Depending on the speed, show the right format
	[[ "$link_speed" -lt 1000 ]] \
		&& link_string=$(printf '%4s bps' "${link_speed}") \
		|| { [[ "$link_speed" -ge 1000 && "$link_speed" -lt 1000000 ]] \
		   && link_string=$(printf '%3s kbps' "$((link_speed / 1000))") ; } \
	|| link_string=$(printf '%3s Mbps' "$((link_speed / 1000000))")

	# Return the current number of bytes and the string to display
	[[ "$link_way" == 'rx' ]] \
		&& echo "${link_bytes_cur}: ${link_string}" \
		|| echo "${link_bytes_cur}: ${link_string}"

	return 0
}

_get_temp(){
	local TEMP
	TEMP="$(( $(</sys/class/hwmon/hwmon0/temp2_input) / 1000 ))"
	echo "$TEMP°C"
}

main
exit $?
