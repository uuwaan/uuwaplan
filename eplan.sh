#!/bin/bash
source `dirname $0`/libplan.sh

if (( 1 > $# )); then
	echo "Usage: eplan [DATE] [CATEGORY] WORDS"
	exit 1;
fi

DATE=$1; shift

plan_edit_entry "$DATE" $*
