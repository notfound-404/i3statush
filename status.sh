#!/bin/bash

# i3statush - A modular status bar for i3 written in BASH 
#
# Copyright (C) 2016 Yann Privé
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

# Main function
main() {
	
	# Local variables
	local i3_vol=' INIT'
	local i3_date=' INIT'
	local i3_cpu='CPU: INIT'
	local i3_ram='RAM: INIT'
	local rx_info='0: INIT'
	local tx_info='0: INIT'
	
	# Infinite loop
	while true
	do

		# Switch on the seconds value
		case "$(date '+%S')" in
		
			# Called every 2 seconds
			[0-5][02468])
				i3_vol=$(get_volume)
				;;&

			# Called every 5 seconds
			[0-5][05])
				i3_date=$(get_date)
				;;&
		
			# Called every second
			*)

				# Gets the CPU and RAM usage
				# i3_cpu=$(get_cpu_usage)
				# i3_ram=$(get_ram_usage)
				
				# Gets the network usage
				rx_info=$(get_net_info 'rx' "${rx_info%:*}")
				tx_info=$(get_net_info 'tx' "${tx_info%:*}")
				;;

		esac
	
		# Echo the line
		echo "${rx_info#*:} - ${tx_info#*:} | ${i3_vol} | ${i3_date}"

		# Sleep 1 second
		sleep 1

	done

	return 0
}

# Gets the current volume
get_volume() {
	
	# Local variables
	local amixer_vol vol_string
	
	# Call amixer to get the current volume
	amixer_vol=$(amixer get Master | grep -m 1 -Eo '[0-9]+%')
	amixer_vol=${amixer_vol::-1}
	
	# Use the right icon
	if [[ "$amixer_vol" -eq 0 ]]
	then
		vol_string=" MUTE"
	
	elif [[ "$amixer_vol" -gt 0 && "$amixer_vol" -le 50 ]]
	then
		vol_string=$(printf ' %3s%%' "${amixer_vol}")

	else
		vol_string=$(printf ' %3s%%' "${amixer_vol}")
	fi

	# Echoes the volume
	echo "$vol_string"

	return 0
}

# Gets the current date
get_date() {

	# Return the date
	echo " $(date '+%d/%m/%y %T')"

	return 0
}

# Gets the network information
get_net_info() {
	
	# Local variables
	local link_way=$1
	local link_bytes_prev=$2
	local link_bytes_cur
	local link_speed
	local link_string
	
	# Get the number of bytes sent / received & gets the speed
	link_bytes_cur=$(cat /sys/class/net/eth0/statistics/${link_way}_bytes)
	link_speed=$(((link_bytes_cur - link_bytes_prev) * 8))

	# Depending on the speed, show the right format
	if [[ "$link_speed" -lt 1000 ]]
	then

		link_string=$(printf '%4s bps' "${link_speed}")
	
	elif [[ "$link_speed" -ge 1000 && "$link_speed" -lt 1000000 ]]
	then
		link_string=$(printf '%3s kbps' "$((link_speed / 1000))")
	
	else
		link_string=$(printf '%3s Mbps' "$((link_speed / 1000000))")
	fi

	# Return the current number of bytes and the string to display
	[[ "$link_way" == 'rx' ]] \
		&& echo "${link_bytes_cur}: ${link_string}" \
		|| echo "${link_bytes_cur}: ${link_string}"

	return 0
}

main
exit $?
