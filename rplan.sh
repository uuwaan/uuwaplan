#!/bin/bash
source `dirname $0`/libplan.sh

if (( 4 > $# )); then
	echo "Usage: rplan [-e] DATE OFFSET ITERATIONS CATEGORY [TEXT]"
	exit 1;
fi

IS_EXT_EDITOR=""
if [[ "-e" == "$1" ]]; then
	IS_EXT_EDITOR="-e"
	shift
fi

DATE=$1; shift

# Need this to preserve offsets like "+1 day"
OFFSET=$1; shift

plan_add_rep_entry $IS_EXT_EDITOR "$DATE" "$OFFSET" $*
