#!/bin/bash
source `dirname $0`/libplan.sh

if (( 2 > $# )); then
	echo "Usage: plan [-e] DATE CATEGORY [TEXT]"
	exit 1;
fi

IS_EXT_EDITOR=""
if [[ "-e" == "$1" ]]; then
	IS_EXT_EDITOR="-e"
	shift
fi

DATE=$1; shift

plan_add_entry $IS_EXT_EDITOR "$DATE" $*
