#!/bin/bash
source `dirname $0`/libplan.sh

if [ -f $PLAN_DATABASE ]; then
	DATES=`plan_month_dates`
fi

DJS=`date +%_d`
CAL=`cal -m`

for i in {1..7}; do
	LINE=`echo "$CAL" | head -$i | tail -1`
	PADD=`printf "%-20s\n" "$LINE"`
	PRNT=`echo "$PADD" | sed s/"\(^\|[^0-9]\)$DJS"'\b'/'\1${color orange}'"$DJS"'$color'/`
	for D in $DATES; do
			SD=`date -d "$D" +%_d`
			if [ "$SD" != "$DJS" ]; then
				PRNT=`echo "$PRNT" | sed s/"\(^\|[^0-9]\)$SD"'\b'/'\1${color red}'"$SD"'$color'/`
			fi
	done
	echo "\${alignr 14}$PRNT"
done
