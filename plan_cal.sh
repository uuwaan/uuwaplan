#!/bin/bash
source `dirname $0`/libplan.sh

if [[ -a "$HOME/.plancalrc" ]]; then
	source $HOME/.plancalrc
fi

if [[ -z `echo $CURRENT_DATE_COLOR` ]]; then
	CURRENT_DATE_COLOR="orange"
fi

if [[ -z `echo $IMPORTANT_COLOR` ]]; then
	IMPORTANT_COLOR="#FF4D00"
fi

if [[ -z `echo $ONLY_IMPORTANT` ]]; then
	ONLY_IMPORTANT=0	
fi

function nth_line()
{
	local MAX_LINES=`echo "$1" | wc -l`

	if (( $MAX_LINES >= $2 )); then
		echo "$1" | head -$2 | tail -1
	fi
}

function colorize_string()
{
	echo "$1" | sed s/"\(^\|[^0-9]\)$2"'\b'/'\1${color '$3'}'"$2"'$color'/
}

function concat_cals()
{
	local i
	for i in {1..8}; do
		local LINE_LEFT=`nth_line "$1" $i`
		local LINE_RIGHT=`nth_line "$2" $i`
		
		if [[ -n "$LINE_LEFT" ]]; then
			echo "$LINE_LEFT" " " "$LINE_RIGHT"
		else
			echo "$LINE_RIGHT"
		fi
	done
}

function cal_for_month()
{
	local DATES
	local CALDATE
	if [[ -n "$1" ]]; then
		DATES=`plan_month_dates "$1" $ONLY_IMPORTANT`
		CALDATE=`date -d "$1" +"%m %Y"`
	else
		DATES=`plan_month_dates now $ONLY_IMPORTANT`
		CALDATE=`date +"%m %Y"`
	fi

	local DJS
	if [[ "$CALDATE" == `date +"%m %Y"` ]]; then
		DJS=`date +%_d`
	else
		DJS=""
	fi

	local CAL=`cal $CALDATE`
	local i
	for i in {1..8}; do
		LINE=`nth_line "$CAL" $i`
		PADD=`printf "%-20s\n" "$LINE"`

		if [[ -n "$DJS" ]]; then
			PRNT=`colorize_string "$PADD" "$DJS" $CURRENT_DATE_COLOR`
		else
			PRNT=$PADD
		fi

		for D in $DATES; do
				SD=`date -d "$D" +%_d`
				if [[ "$SD" != "$DJS" ]]; then
					PRNT=`colorize_string "$PRNT" "$SD" $IMPORTANT_COLOR`
				fi
		done

		echo "$PRNT"
	done
}

COUNT=0
if [[ -n "$2" ]]; then
	let COUNT=$2-1
fi

RESULT=""

for i in `seq 0 $COUNT`; do
	CUR_CAL=`cal_for_month "$1 +$i month"`
	RESULT=`concat_cals "$RESULT" "$CUR_CAL"`
done

for i in {1..8}; do
	LINE=`nth_line "$RESULT" $i`
	echo "$LINE"
done
