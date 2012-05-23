#!/bin/bash
source `dirname $0`/libplan.sh

if [ -f $HOME/.plancalrc ]; then
	source $HOME/.plancalrc
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

if [ "x$ONLY_IMPORTANT" == "x" ]; then
	ONLY_IMPORTANT=0	
fi

if [ 1 -gt $ONLY_IMPORTANT ]; then
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
			if [ "$SD" != "$DJS" ]; then
				PRNT=`colorize_string "$PRNT" "$SD" $IMPORTANT_COLOR`
			fi
	done
	echo "\${alignr $PX_OFFSET}$PRNT"
done
