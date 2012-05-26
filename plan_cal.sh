#!/bin/bash
source `dirname $0`/libplan.sh

if [[ -a "$HOME/.plancalrc" ]]; then
	source $HOME/.plancalrc
fi

if [[ -z `echo $PX_OFFSET` ]]; then
	PX_OFFSET=14
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

if (( 0 == $ONLY_IMPORTANT )); then
	DATES=`plan_month_dates`
else
	DATES=`plan_important_dates`
fi

DJS=`date +%_d`
CAL=`cal -m`

function nth_line()
{
	echo "$1" | head -$2 | tail -1
}

function colorize_string()
{
	echo "$1" | sed s/"\(^\|[^0-9]\)$2"'\b'/'\1${color '$3'}'"$2"'${color}'/
}

for i in {1..7}; do
	LINE=`nth_line "$CAL" $i`
	PADD=`printf "%-20s\n" "$LINE"`
	PRNT=`colorize_string "$PADD" "$DJS" $CURRENT_DATE_COLOR`
	for D in $DATES; do
			SD=`date -d "$D" +%_d`
			if [[ "$SD" != "$DJS" ]]; then
				PRNT=`colorize_string "$PRNT" "$SD" $IMPORTANT_COLOR`
			fi
	done
	echo "\${alignr $PX_OFFSET}$PRNT"
done
