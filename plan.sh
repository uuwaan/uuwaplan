#!/bin/bash
source `dirname $0`/libplan.sh

if (( 2 > $# )); then
	echo "Usage: plan (a[dd]|r[epeat]|m[ove]|e[dit]) PARAMETERS"
	echo "add:"
	echo "        Adds new entry." 
	echo "        Arguments are: [-e] DATE GROUP [TEXT]"
	echo "repeat:"
	echo "        Adds new entry and repeats it."
	echo "        Arguments are: [-e] DATE OFFSET ITERATIONS GROUP [TEXT]"
	echo "move:"
	echo "        Moves entry between dates."
	echo "        Arguments are: NEW_DATE [OLD_DATE] [GROUP] WORDS"
	echo "edit:"
	echo "        Edits existing entry in DB."
	echo "        Arguments are: [DATE] [GROUP] WORDS"
	exit 1;
fi

COMMAND=$1; shift

IS_EXT_EDITOR=""
if [[ "-e" == "$1" ]]; then
	IS_EXT_EDITOR="-e"
	shift
fi

# Doing this because date may consist of 2 or more words
# And passing with $* will break it
MAYBE_DATE=$1; shift

case "$COMMAND" in
	a|add)
		plan_add_entry $IS_EXT_EDITOR "$MAYBE_DATE" $*
	;;
	r|repeat)
		OFFSET=$1; shift
		plan_add_rep_entry $IS_EXT_EDITOR "$MAYBE_DATE" "$OFFSET" $*
	;;
	m|move)
		plan_move_entry "$MAYBE_DATE" $*
	;;
	e|edit)
		plan_edit_entry "$MAYBE_DATE" $*
	;;
esac


