#!/bin/bash
source `dirname $0`/libplan.sh

if [ -f $HOME/.weekplanrc ]; then
	source $HOME/.weekplanrc
fi

if [ "x$OVERALL_WIDTH" == "x" ]; then
	OVERALL_WIDTH=50
fi

if [ "x$TAG_FIELD_WIDTH" == "x" ]; then
	TAG_FIELD_WIDTH=6
fi

if [ "x$PX_OFFSET" == "x" ]; then
	PX_OFFSET=14
fi

if [ "x$HILITE_COLOR" == "x" ]; then
	HILITE_COLOR="orange"
fi

if [ "x$CON_OUTPUT" == "x" ]; then
	CON_OUTPUT=0	
fi

	
TXT_FIELD_WIDTH=`echo $OVERALL_WIDTH - $TAG_FIELD_WIDTH - 1 | bc`

NOW=`date +%Y%m%d`

function print_entry()
{
	local STAMP=$1; shift
	local GROUP=$1; shift

# Made this because printf behaves nasty with multibyte chars 
	local ATEXT=`echo "$*" | iconv -f utf8 -t cp1251`

	if [ "$STAMP" != "$PREVSTAMP" ]; then
		local TEMPLATE="%$OVERALL_WIDTH""s"

		if [ $CON_OUTPUT -ne 1 ]; then
			if [ "$STAMP" == "$NOW" ]; then 
				TEMPLATE="\${offset $PX_OFFSET}\${color $HILITE_COLOR}$TEMPLATE\${color}"
			else
				TEMPLATE="\${offset $PX_OFFSET}$TEMPLATE"
			fi
		fi

		printf "\n\n""$TEMPLATE""\n" `date -d "$STAMP" "+%Y-%m-%d"`

		PREVSTAMP=$STAMP
	fi

	if [ $CON_OUTPUT -ne 1 ]; then
		echo -n "\${offset $PX_OFFSET}"
	fi

# Restoring UTF-8 text	
	printf "%-$TXT_FIELD_WIDTH""s %$TAG_FIELD_WIDTH""s\n" "$ATEXT" "$GROUP" | iconv -f cp1251 -t utf8
}

plan_week_entries | while read LINE; do
	print_entry $LINE
done
