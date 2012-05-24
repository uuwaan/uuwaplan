#!/bin/bash
source `dirname $0`/libplan.sh

if (( 2 > $# )); then
	echo "Usage: mvplan NEW_DATE [CATEGORY] WORDS"
	exit 1;
fi

DATE=$1; shift

plan_move_entry "$DATE" $*
