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

if [ "x$CURRENT_DATE_COLOR" == "x" ]; then
	CURRENT_DATE_COLOR="orange"
fi

if [ "x$IMPORTANT_COLOR" == "x" ]; then
	IMPORTANT_COLOR="#FF4D00"
fi

if [ "x$FLOW_MODE" == "x" ]; then
	FLOW_MODE=0
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
	local TEMPLATE

	if [ "$STAMP" != "$PREVSTAMP" ]; then
		TEMPLATE="%$OVERALL_WIDTH""s"

		if [ $CON_OUTPUT -ne 1 ]; then
			if [ "$STAMP" == "$NOW" ]; then 
				TEMPLATE="\${offset $PX_OFFSET}\${color $CURRENT_DATE_COLOR}$TEMPLATE\${color}"
			else
				TEMPLATE="\${offset $PX_OFFSET}$TEMPLATE"
			fi
		fi

		printf "\n\n""$TEMPLATE""\n" `date -d "$STAMP" "+%Y-%m-%d"`

		PREVSTAMP=$STAMP
	fi

	TEMPLATE="%-$TXT_FIELD_WIDTH""s %$TAG_FIELD_WIDTH""s"
	if [ 1 -ne $CON_OUTPUT ]; then
		TEMPLATE="\${offset $PX_OFFSET}"$TEMPLATE
		IS_IMP=$(is_important "$GROUP")

		if [ -n "$IS_IMP" ]; then
			TEMPLATE="\${color $IMPORTANT_COLOR}"$TEMPLATE"\${color}"
			printf "$TEMPLATE\n" "$ATEXT" "$IS_IMP" | iconv -f cp1251 -t utf8
			return
		fi
	fi

	printf "$TEMPLATE\n" "$ATEXT" "$GROUP" | iconv -f cp1251 -t utf8
}

plan_week_entries $FLOW_MODE | while read LINE; do
	print_entry $LINE
done
