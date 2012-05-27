#!/bin/bash
source `dirname $0`/libplan.sh

if [[ -a "$HOME/.weekplanrc" ]]; then
	source "$HOME/.weekplanrc"
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

NOW=`date +%Y%m%d`
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

plan_date_entries "$1" "$2" "$3" | while read LINE; do
	print_entry $LINE
done
