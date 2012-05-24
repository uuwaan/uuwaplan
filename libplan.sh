#!/bin/bash
if [ "x$PLAN_DATABASE" == "x" ]; then
	export PLAN_DATABASE=$HOME/.plans.txt
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

# Creates simple regexp from specified words
function plan_pattern_from_words()
{
	local PATTERN=".*"
	for i in `seq 1 $#`; do
		PATTERN=$PATTERN$1".*"
		shift
	done

	echo $PATTERN
}

# Shows whether this entry is important or not
function is_important()
{
	echo $1 | grep ! > /dev/null

	if (( 1 != $? )); then
		echo $1 | sed s/\!//
	fi
}

# Reads database line by line and invokes callback function
function plan_read_lines()
{
	local LINE
	local RESULT
	cat $PLAN_DATABASE | sort | while read LINE; do
		RESULT=$($1 $LINE)
		if [[ -n "$RESULT" ]]; then
			echo $RESULT 	
		fi
	done
}

# Shows dates with active entries in current month
function plan_month_dates()
{
	local TIME_NOW=`date +%Y%m%d`
	local TIME_END=`date -d "-$(date +%d) days +1 month" +%Y%m%d`

	local LINE
	plan_read_lines "plan_filter_by_date $TIME_NOW $TIME_END" | while read LINE; do
		echo $LINE | awk '{ print $1 }'
	done
}

# Shows dates with active important entries in current month
function plan_important_dates()
{
	local TIME_NOW=`date +%Y%m%d`
	local TIME_END=`date -d "-$(date +%d) days +1 month" +%Y%m%d`

	local LINE
	plan_read_lines "plan_filter_by_date $TIME_NOW $TIME_END" | while read LINE; do
		local IS_IMP=$(is_important `echo $LINE | awk '{ print $2 }'`)
		if [[ -n "$IS_IMP" ]]; then
			echo $LINE | awk '{ print $1 }'
		fi
	done
}

# Shows lines that have date within current week
function plan_week_entries()
{
	local TIME_NOW=`date +%Y%m%d`

	if (( 1 <= $1 )); then
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
	local TIMESTAMP=`date -d "$1" +%Y%m%d`; shift
	if (( $? )); then
		echo "plan_add_entry: wrong date format"
		return
	fi

	local CATEGORY=$1; shift
	echo "$TIMESTAMP" "$CATEGORY" "$*"  >> $PLAN_DATABASE 
}

# Adds number of repetive entries from specified date with specified offset 
function plan_add_rep_entry()
{
	local CURDATE=`date -d "$1" +%Y%m%d`; shift
	if (( $? )); then
		echo "plan_add_rep_entry: wrong date format"
		return
	fi

	local	OFFSET=$1; shift
	local ITERATIONS=$1; shift

	for i in `seq 1 $ITERATIONS`; do
		plan_add_entry $CURDATE $* 
		CURDATE=`date -d "$CURDATE $OFFSET" +%Y%m%d`
	done
}

# Moves entry to new date
function plan_move_entry()
{
	local NEW_DATE=`date -d "$1" +%Y%m%d`; shift
	if (( $? )); then
		echo "plan_move_entry: wrong date format"
		return
	fi

	local PATTERN=`plan_pattern_from_words $*`
	local DB_FILE=$PLAN_DATABASE.edit

	if [[ -a $DB_FILE ]]; then
		rm -f $DB_FILE
	fi

	local LINE
	plan_read_lines "echo" | while read LINE; do
		if [[ -n `plan_filter_by_text "$PATTERN" $LINE` ]]; then
			local REST=`echo $LINE | cut -d\  -f2-`
			echo $NEW_DATE $REST >> $DB_FILE
			continue
		fi
		echo $LINE >> $DB_FILE
	done

	mv $DB_FILE $PLAN_DATABASE
}
