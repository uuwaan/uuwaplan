#!/bin/bash
source `dirname $0`/libplan.sh

NOW=`date +%Y%m%d`

function print_entry()
{
	local STAMP=$1; shift
	local GROUP=$1; shift

# Made this because printf behaves nasty with multibyte chars 
	local ATEXT=`echo "$*" | iconv -f utf8 -t cp1251`

	if [ "$STAMP" != "$PREVSTAMP" ]; then
		printf "\n\n"
		if [ "$STAMP" == "$NOW" ]; then echo -n "\${color orange}"; fi
		printf "\${offset 14}%52s" "`date -d "$STAMP" "+%Y-%m-%d"`"
		if [ "$STAMP" == "$NOW" ]; then echo -n "\${color}"; fi
		printf "\n"

		PREVSTAMP=$STAMP
	fi

# Restoring UTF-8 text	
	printf "\${offset 14}%-45s %6s\n" "$ATEXT" "$GROUP" | iconv -f cp1251 -t utf8
}

plan_week_entries | while read LINE; do
	print_entry $LINE
done
