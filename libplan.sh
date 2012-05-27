#!/bin/bash
if [[ -z `echo $PLAN_DATABASE` ]]; then
	PLAN_DATABASE="$HOME/.plans.txt"
fi

# Reads entire database
function plan_read_lines()
{
	cat "$PLAN_DATABASE" | sort
}

# Filters lines by text pattern 
function plan_filter_by_text()
{
	local LINE
	local RESULT
	while read LINE; do
		if [[ "$LINE" =~ $1 ]]; then
			echo $LINE
		fi
	done
}

# Filters lines by importance 
function plan_filter_by_imp()
{
	local LINE
	local GROUP 
	while read LINE; do
		GROUP=`echo "$LINE" | plan_ex_field 2`
		if [[ -n `plan_is_important $GROUP` ]]; then
			echo $LINE
		fi
	done
}

# Filters lines by date range 
function plan_filter_by_date()
{
	local LINE
	local STAMP
	while read LINE; do
		STAMP=`echo $LINE | plan_ex_field 1`
		if (($STAMP >= $1 && $2 >= $STAMP)); then
			echo $LINE 
		fi
	done
}

# Extracts field from lines
function plan_ex_field()
{
	local LINE
	while read LINE; do
		echo $LINE | awk "{ print \$$1 }"
	done
}

# Cuts the lines on certain position 
function plan_cut_line()
{
	local LINE
	while read LINE; do
		echo $LINE | cut -d\  -f$1- 
	done
}

# Invokes external editor for entry
function plan_edit_externally()
{
	local SALT=`date +%T%N`
	local SUFFIX=`echo $* $SALT | sha1sum | awk '{print $1}'`
	local FILE=$PLAN_DATABASE.$SUFFIX

	echo $* > "$FILE"
	PLAN_LAST_EDIT=""
	if [[ -n `echo $EDITOR` ]]; then
# Workaround, as editor wasn't opened with direct connection to terminal
		$EDITOR "$FILE" < /dev/tty
		if (( 0 == $? )); then
			PLAN_LAST_EDIT=`cat "$FILE" | head -1`
		fi
	else
		echo 'plan_edit_externally: no external editor found in EDITOR variable. Do smth like "export EDITOR=mcedit"'
	fi
	rm -f "$FILE"
}

# Creates simple regexp from specified arguments 
function plan_pattern_from_args()
{
# Try to interpret first argument as timestamp to narrow search
	local PATTERN
	local TRY_DATE=`plan_parse_date "$1"`
	if [[ -n "$TRY_DATE" ]]; then
		PATTERN=$TRY_DATE".*"
		shift
	else
		PATTERN=".*"
	fi

	for i in `seq 1 $#`; do
		PATTERN=$PATTERN$1".*"
		shift
	done

	echo $PATTERN
}

# Copies lines that didn't match the pattern to file and echoes others. 
function plan_hook_lines()
{
	local LINE
	while read LINE; do
		if [[ -n `echo "$LINE" | plan_filter_by_text "$2"` ]]; then
			echo $LINE
		else
			echo $LINE >> $1
		fi
	done
}

# Returns DB timestamp if input can be interpreted as date
function plan_parse_date()
{
	echo "$1" | grep -e '[a-z0-9[:space:]+-]\+' >/dev/null
	if (( 1 == $? )); then return; fi

	local TRY_DATE=`date +%Y%m%d -d "$1" 2>/dev/null`
	if (( 1 == $? )); then return; fi

	echo $TRY_DATE
}

# Shows whether this entry is important or not
function plan_is_important()
{
	echo $1 | grep ! > /dev/null

	if (( 0 == $? )); then
		echo $1 | sed s/\!//
	fi
}

# Shows dates with active entries in specified month
function plan_month_dates()
{
	local MONTH

	if [[ -n `plan_parse_date "$1"` ]]; then
		MONTH=`date -d "$1" +%m`
	else
		MONTH=`date +%m`
	fi

	local TIMESTART=`date -d "$MONTH/01" +%Y%m%d`
	local TIMEND=`date -d "$TIMESTART -1 day +1 month" +%Y%m%d`

	local CONVEYER="plan_read_lines | plan_filter_by_date $TIMESTART $TIMEND"
	if [[ "1" == "$2" ]]; then
		CONVEYER=$CONVEYER" | plan_filter_by_imp"
	fi

	local LINE
	local PREVSTAMP=-1
	eval "$CONVEYER" | while read LINE; do
		local STAMP=`echo $LINE | plan_ex_field 1`

		if [[ "$STAMP" != "$PREVSTAMP" ]]; then
			echo $STAMP
			PREVSTAMP=$STAMP
		fi
	done
}

# Shows lines that have date within specified range 
function plan_date_entries()
{
	local TIMESTART=`plan_parse_date "$1"`; shift
	if [[ -z "$TIMESTART" ]]; then
		echo "plan_date_entries: wrong date format for start date"
		return
	fi

	local TIMEND=`plan_parse_date "$1"`; shift
	if [[ -z "$TIMEND" ]]; then
		echo "plan_date_entries: wrong date format for end date"
		return
	fi

	local CONVEYER="plan_read_lines | plan_filter_by_date $TIMESTART $TIMEND"
	local LINE
	local i=0
	local LIMIT=$1; shift
	eval "$CONVEYER" | while read LINE; do
		echo $LINE
		let i+=1
		if (( $LIMIT <= $i )); then break; fi
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

	local TIMESTAMP=`plan_parse_date "$1"`; shift
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

	local TIMESTAMP=`plan_parse_date "$1"`; shift
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
	local NEW_DATE=`plan_parse_date "$1"`; shift
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
	local CONVEYER="plan_read_lines | plan_hook_lines \"$DB_FILE\" \"$PATTERN\" | plan_cut_line 2"
	eval "$CONVEYER" | while read LINE; do
		echo $NEW_DATE $LINE >> "$DB_FILE"
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
	local CONVEYER="plan_read_lines | plan_hook_lines \"$DB_FILE\" \"$PATTERN\""
	eval "$CONVEYER" | while read LINE; do
		plan_add_entry -e -db "$DB_FILE" $LINE
	done

	mv "$DB_FILE" "$PLAN_DATABASE"
}
