#!/bin/bash
source `dirname $0`/libplan.sh

if [ 5 -gt $# ]; then
	echo "Usage: rplan DATE OFFSET ITERATIONS CATEGORY TEXT"
	exit 1;
fi

DATE=$1; shift

# Need this to preserve offsets like "+1 day"
OFFSET=$1; shift

plan_add_rep_entry "$DATE" "$OFFSET" $*
