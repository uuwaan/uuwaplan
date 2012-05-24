#!/bin/bash
source `dirname $0`/libplan.sh

if (( 3 > $# )); then
	echo "Usage: plan DATE CATEGORY TEXT"
	exit 1;
fi

DATE=$1; shift

plan_add_entry "$DATE" $*
