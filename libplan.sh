#!/bin/bash
if [[ -z `echo $PLAN_DATABASE` ]]; then
	PLAN_DATABASE="$HOME/.plans.txt"
fi

if [[ -z `echo $PLAN_LAST_EDIT` ]]; then
	PLAN_LAST_EDIT=""
fi

# Filters lines by text pattern 
function plan_filter_by_text()
{
	local FILTER=$1; shift
	local RESULT=`echo "$*" | awk '/'"$FILTER"'/ { print $0 }'`

	if [ -n "$RESULT" ]; then
		echo $RESULT
	fi
}

# Filters lines by date range 
function plan_filter_by_date()
{
	local DATE_FROM=$1; shift
	local DATE_TO=$1; shift

	if (($1 >= $DATE_FROM && $1 <= $DATE_TO)); then
		echo $* 
	fi
}

# Invokes external editor for entry
function plan_edit_externally()
{
	local SALT=`date +%T%N`
	local SUFFIX=`echo $* $SALT | sha1sum | awk '{print $1}'`
	local FILE=$PLAN_DATABASE.$SUFFIX

	echo $* > $FILE
	if [[ -n `echo $EDITOR` ]]; then
# Workaround, as editor wasn't opened with direct connection to terminal
		$EDITOR $FILE < /dev/tty
		if (( 0 == $? )); then
			PLAN_LAST_EDIT=`cat $FILE | head -1`
		fi
	else
		echo 'plan_edit_externally: no external editor found in EDITOR variable. Do smth like "export EDITOR=mcedit"'
	fi
	rm -f $FILE
}

# Creates simple regexp from specified arguments 
function plan_pattern_from_args()
{
# Try to interpret first argument as timestamp to narrow search
	local TRY_DATE=`plan_is_date "$1"`
	if [[ -n "$TRY_DATE" ]]; then
		local PATTERN=$TRY_DATE".*"
		shift
	else
		local PATTERN=".*"
	fi

	for i in `seq 1 $#`; do
		PATTERN=$PATTERN$1".*"
		shift
	done

	echo $PATTERN
}

# Shows whether this entry is important or not
function plan_is_important()
{
	echo $1 | grep ! > /dev/null

	if (( 0 == $? )); then
		echo $1 | sed s/\!//
	fi
}

# Returns DB timestamp if input can be interpreted as date
function plan_is_date()
{
	echo "$1" | grep -e '[a-z0-9[:space:]+-]\+' >/dev/null
	if (( 1 == $? )); then return; fi

	local TRY_DATE=`date +%Y%m%d -d "$1" 2>/dev/null`
	if (( 1 == $? )); then return; fi

	echo $TRY_DATE
}

# Reads database line by line and invokes callback function
function plan_read_lines()
{
	local LINE
	local RESULT
	cat "$PLAN_DATABASE" | sort | while read LINE; do
		RESULT=$($1 $LINE)
		if [[ -n "$RESULT" ]]; then
			echo $RESULT 	
		fi
	done
}

# Reads database line by line, copies lines that didn't match the pattern and echoes others. 
function plan_hook_lines()
{
	local LINE
	plan_read_lines "echo" | while read LINE; do
		if [[ -n `plan_filter_by_text "$2" $LINE` ]]; then
			echo $LINE
		else
			echo $LINE >> $1
		fi
	done
}

# Shows dates with active entries in current month
function plan_month_dates()
{
	local TIME_NOW
	local TIME_END

	if [[ -n `plan_is_date "$1"` ]]; then
		local MONTH=`date -d "$1" +%m`
		if (( 1 == $? )); then
			echo "plan_month_dates: wrong date format"
			return
		fi

		TIME_NOW=`date -d "$MONTH/01" +%Y%m%d`
		TIME_END=`date -d "$TIME_NOW -1 day +1 month" +%Y%m%d`
	else
		TIME_NOW=`date +%Y%m%d`
		TIME_END=`date -d "-$(date +%d) days +1 month" +%Y%m%d`
	fi

	local LINE
	local PREVSTAMP=-1
	plan_read_lines "plan_filter_by_date $TIME_NOW $TIME_END" | while read LINE; do
		local STAMP=`echo $LINE | awk '{ print $1 }'`
		local IS_IMP=$(plan_is_important `echo $LINE | awk '{ print $2 }'`)

		if [[ "1" == "$2" && -z "$IS_IMP" ]]; then
			continue
		fi

		if [[ "$STAMP" != "$PREVSTAMP" ]]; then
			echo $STAMP
			PREVSTAMP=$STAMP
		fi
	done
}

# Shows lines that have date within current week
function plan_week_entries()
{
	local TIME_NOW=`date +%Y%m%d`

	if (( 0 != $1 )); then
		local TIME_END=`date -d "+7 day" +%Y%m%d`
	else
		local TIME_END=`date -d "next Mon" +%Y%m%d`
	fi

	local LINE
	plan_read_lines "plan_filter_by_date $TIME_NOW $TIME_END" | while read LINE; do
		echo $LINE
	done
}

# Adds single entry to plan database
function plan_add_entry()
{
	local IS_EXT_EDITOR=1
	if [[ "-e" == "$1" ]]; then
		IS_EXT_EDITOR=0
		shift
	fi

	local ALT_DB=""
	if [[ "-db" == "$1" ]]; then
		ALT_DB=$2
		shift
		shift
	fi

	local TIMESTAMP=`plan_is_date "$1"`; shift
	if [[ -z "$TIMESTAMP" ]]; then
		echo "plan_add_entry: wrong date format"
		return
	fi

	local CATEGORY=$1; shift
	if [[ -z `echo $CATEGORY` ]]; then
		echo "plan_add_entry: category was not specified"
		return
	fi

	local RESULT
	if (( 0 == $IS_EXT_EDITOR )); then
		plan_edit_externally $CATEGORY $*
		RESULT=$PLAN_LAST_EDIT
	else
# Without echo this line doesn't behave good with russian text
		RESULT=`echo $CATEGORY $*`
	fi
	
	if [[ -z `echo $RESULT` || `echo $RESULT` == "$CATEGORY" ]]; then
		echo "plan_add_entry: nothing to add"
		return
	fi

	if [[ -n "$ALT_DB" ]]; then
		echo $TIMESTAMP $RESULT >> "$ALT_DB" 
	else
		echo $TIMESTAMP $RESULT >> "$PLAN_DATABASE" 
	fi
}

# Adds number of repetive entries from specified date with specified offset 
function plan_add_rep_entry()
{
	local IS_EXT_EDITOR=""
	if [[ "-e" == "$1" ]]; then
		IS_EXT_EDITOR="-e"
		shift
	fi

	local TIMESTAMP=`plan_is_date "$1"`; shift
	if [[ -z "$TIMESTAMP" ]]; then
		echo "plan_add_rep_entry: wrong date format"
		return
	fi

	local	OFFSET=$1; shift
	local ITERATIONS=$1; shift
	local MESSAGE=$*

	for i in `seq 1 $ITERATIONS`; do
		plan_add_entry $IS_EXT_EDITOR $TIMESTAMP $MESSAGE 
		TIMESTAMP=`date -d "$TIMESTAMP $OFFSET" +%Y%m%d`

# Check if we're using external editor and save it's output
# to avoid repeating input each time
		if [[ -n "$IS_EXT_EDITOR" && -n "$PLAN_LAST_EDIT" ]]; then
			MESSAGE=$PLAN_LAST_EDIT
			IS_EXT_EDITOR=""
		fi
	done
}

# Moves entry to new date
function plan_move_entry()
{
	local NEW_DATE=`plan_is_date "$1"`; shift
	if [[ -z "$NEW_DATE" ]]; then
		echo "plan_move_entry: wrong date format"
		return
	fi

	local PATTERN=`plan_pattern_from_args $*`
	local DB_FILE="$PLAN_DATABASE.edit"

	if [[ -a "$DB_FILE" ]]; then
		rm -f "$DB_FILE"
	fi

	local LINE
	plan_hook_lines "$DB_FILE" "$PATTERN" | while read LINE; do
		local REST=`echo $LINE | cut -d\  -f2-`
		echo $NEW_DATE $REST >> "$DB_FILE"
	done

	mv "$DB_FILE" "$PLAN_DATABASE"
}

# Edits entry with external editor 
function plan_edit_entry()
{
	local PATTERN=`plan_pattern_from_args $*`
	local DB_FILE="$PLAN_DATABASE.edit"

	if [[ -a "$DB_FILE" ]]; then
		rm -f "$DB_FILE"
	fi

	local LINE
	plan_hook_lines "$DB_FILE" "$PATTERN" | while read LINE; do
		local REST=`echo $LINE | cut -d\  -f2-`
		local TIME=`echo $LINE | awk '{ print $1 }'`

# Using secret ability of plan_add_entry to add line to new DB instead of main
		plan_add_entry -e -db "$DB_FILE" $TIME $REST
	done

	mv "$DB_FILE" "$PLAN_DATABASE"
}
