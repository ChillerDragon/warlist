#!/bin/bash

errors=0

check_dupe_names() {
	local namefile="$1"
	local name
	local sarchfile
	local match
	local duplicates=0
	if [ ! -f "$namefile" ]
	then
		return
	fi
	while IFS= read -r name
	do
		if [ "$(echo "$name" | xargs -0)" == "" ]
		then
			continue
		fi
		for searchfile in ./{war,war_,team,team_,traitor,traitor_}/*/names.txt
		do
			[[ -f "$searchfile" ]] || continue
			[[ "$searchfile" == "$namefile" ]] && continue

			match=''
			match="$(name="$name" awk 'substr($0, 1, length(ENVIRON["name"])) == ENVIRON["name"] { print }' "$searchfile")"
			if [ "$match" != "" ]
			then
				if [ "$duplicates" == "0" ]
				then
					echo "ERROR"
				fi
				duplicates="$((duplicates+1))"
				echo "Found name '$name' twice in these files:"
				echo "  $namefile"
				echo "  $searchfile"
			fi
		done
	done < "$namefile"
	if [ "$duplicates" == "0" ]
	then
		return 1
	fi
	return 0
}

function check_all_names() {
	local namefile
	local name
	for namefile in ./{war,war_,team,team_,traitor,traitor_}/*/names.txt
	do
		[[ -f "$namefile" ]] || continue

		folder="${namefile%/*}"
		name="${namefile%/*}"
		name="${name##*/}"
		echo -n "[*] checking '$name' .. "
		if [ ! -f "$folder"/reason.txt ]
		then	
			echo "WARN"
			echo "  missing reason file in $folder"
		elif ! check_dupe_names "$namefile"
		then
			echo "OK"
		else
			errors="$((errors+1))"
		fi
	done
}

check_all_names

if [ "$errors" -gt "0" ]
then
	echo "[-] errors $errors"
	exit 1
else
	echo "[+] no duplicated names found"
fi

