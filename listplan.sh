#!/bin/bash
source `dirname $0`/libplan.sh

if [[ -a "$HOME/.listplanrc" ]]; then
	source "$HOME/.listplanrc"
fi

if [[ -z `echo $OVERALL_WIDTH` ]]; then
	OVERALL_WIDTH=50
fi

if [[ -z `echo $TAG_FIELD_WIDTH` ]]; then
	TAG_FIELD_WIDTH=6
fi

if [[ -z `echo $CURRENT_DATE_COLOR` ]]; then
	CURRENT_DATE_COLOR="orange"
fi

if [[ -z `echo $IMPORTANT_COLOR` ]]; then
	IMPORTANT_COLOR="#FF4D00"
fi

if [[ -z `echo $CON_OUTPUT` ]]; then
	CON_OUTPUT=0	
fi

	
let TXT_FIELD_WIDTH=$OVERALL_WIDTH-$TAG_FIELD_WIDTH-1

NOW=`plan_parse_date now`
PREVSTAMP=-1
IS_FIRST=1

function print_entry()
{
	local STAMP=$1; shift
	local GROUP=$1; shift

# Made this because printf behaves nasty with multibyte chars 
	local ATEXT=`echo "$*" | iconv -f utf8 -t cp1251`
	local AGROUP=`echo "$GROUP" | iconv -f utf8 -t cp1251`
	local TEMPLATE

	if (( $STAMP != $PREVSTAMP )); then
		TEMPLATE="%$OVERALL_WIDTH""s"

		if (( 0 == $CON_OUTPUT && $STAMP == $NOW )); then
			TEMPLATE="\${color $CURRENT_DATE_COLOR}$TEMPLATE\$color"
		fi

		if (( $IS_FIRST )); then
			printf "$TEMPLATE""\n\n" `date -d "$STAMP" "+%Y-%m-%d"`
			IS_FIRST=0
		else
			printf "\n\n\n""$TEMPLATE""\n\n" `date -d "$STAMP" "+%Y-%m-%d"`
		fi

		PREVSTAMP=$STAMP
	fi

	TEMPLATE="%-$TXT_FIELD_WIDTH""s %$TAG_FIELD_WIDTH""s"
	if (( 0 == $CON_OUTPUT )); then
		IS_IMP=$(plan_is_important "$AGROUP")

		if [[ -n "$IS_IMP" ]]; then
			TEMPLATE="\${color $IMPORTANT_COLOR}"$TEMPLATE"\$color"
			printf "$TEMPLATE\n" "$ATEXT" "$IS_IMP" | iconv -f cp1251 -t utf8
			return
		fi
	fi

	printf "$TEMPLATE\n" "$ATEXT" "$AGROUP" | iconv -f cp1251 -t utf8
}

if [[ -n "$1" ]]; then
	START_DATE=`plan_parse_date "$1"`
	if [[ -z "$START_DATE" ]]; then
		START_DATE=now
	fi
else
	START_DATE=now
fi

if [[ -n "$2" ]]; then
	STOP_DATE=`plan_parse_date "$2"`
	if [[ -z "$STOP_DATE" ]]; then
		STOP_DATE="$START_DATE +7 day"
	fi
else
	STOP_DATE="$START_DATE +7 day"
fi

if [[ -n "$3" ]]; then
	COUNT=$3
else
	COUNT=100500
fi

plan_date_entries "$START_DATE" "$STOP_DATE" "$COUNT" | while read LINE; do
	print_entry $LINE
done
