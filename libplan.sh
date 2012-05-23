#!/bin/bash

if [ "x$PLAN_DATABASE" == "x" ]; then
	export PLAN_DATABASE=$HOME/.plans.txt
fi

# Adds single entry to plan database
function plan_add_entry()
{
	if [ $# -lt 3 ]; then
		echo "plan_add_entry: not enough parameters."
		echo "Usage: plan_edd_entry DATE CATEGORY TEXT"
		exit 1;
	fi

	local TIMESTAMP=`date -d "$1" +%Y%m%d`; shift
	if [ 0 -ne $? ]; then
		echo "plan_add_entry: wrong date format"
		exit 1;
	fi

	local CATEGORY=$1; shift
	echo "$TIMESTAMP" "$CATEGORY" "$*"  >> $PLAN_DATABASE 
}

# Adds number of repetive entries from specified date with specified offset 
function plan_add_rep_entry()
{
	if [ $# -lt 5 ]; then
		echo "plan_add_entry: not enough parameters."
		echo "Usage: plan_edd_rep_entry DATE OFFSET ITERATIONS CATEGORY TEXT"
		exit 1;
	fi

	local CURDATE=`date -d "$1" +%Y%m%d`; shift
	local	OFFSET=$1; shift
	local ITERATIONS=$1; shift

	for i in `seq 1 $ITERATIONS`; do
		plan_add_entry $CURDATE $* 
		CURDATE=`date -d "$CURDATE $OFFSET" +%Y%m%d`
	done
}

# Reads database line by line and invokes callback function
function plan_read_lines()
{
	if [ $# -lt 1 ]; then
		echo "plan_read_lines: not enough parameters."
		echo "Usage: plan_read_lines CALLBACK"
		exit 1;
	fi
	
	local LINE
	local RESULT
	cat $PLAN_DATABASE | sort | while read LINE; do
		RESULT=$($1 $LINE)
		if [ x"$RESULT" != "x" ]; then
			echo $RESULT 	
		fi
	done
}

# Read the date from line and returns it if it is in specified range
function plan_get_line_from_range()
{
	if [ $# -lt 3 ]; then
		echo "plan_get_line_from_range: not enough parameters."
		echo "Usage: plan_get_line_from_range DATE_FROM DATE_TO LINE"
		exit 1;
	fi

	local DATE_FROM=$1; shift
	local DATE_TO=$1; shift

	if [ $1 -ge $DATE_FROM -a $1 -le $DATE_TO ]; then
		echo "$*" 
	fi
}

# Shows dates with active entries in current month
function plan_month_dates()
{
	local TIME_NOW=`date +%Y%m%d`
	local TIME_END=`date -d "-$(date +%d) days +1 month" +%Y%m%d`

	local LINE
	plan_read_lines "plan_get_line_from_range $TIME_NOW $TIME_END" | while read LINE; do
		echo $LINE | awk '{ print $1 }'
	done
}

# Shows dates with active important entries in current month
function plan_important_dates()
{
	local TIME_NOW=`date +%Y%m%d`
	local TIME_END=`date -d "-$(date +%d) days +1 month" +%Y%m%d`

	local LINE
	plan_read_lines "plan_get_line_from_range $TIME_NOW $TIME_END" | while read LINE; do
		local IS_IMP=$(is_important `echo $LINE | awk '{ print $2 }'`)
		if [ -n "$IS_IMP" ]; then
			echo $LINE | awk '{ print $1 }'
		fi
	done
}

# Shows lines that have date within current week
function plan_week_entries()
{
	local TIME_NOW=`date +%Y%m%d`
	local TIME_END=`date -d "next Mon" +%Y%m%d`

	local LINE
	plan_read_lines "plan_get_line_from_range $TIME_NOW $TIME_END" | while read LINE; do
		echo $LINE
	done
}

# Shows whether this entry is important or not
function is_important()
{
	echo $1 | grep ! > /dev/null

	if [ 1 -ne $? ]; then
		echo $1 | sed s/\!//
	fi
}
