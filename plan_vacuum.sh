#!/bin/bash
source `dirname $0`/libplan.sh

TIME_NOW=`date +%Y%m%d`
TIME_END=`date -d "-$(date +%d) days +100 year" +%Y%m%d`
DB_FILE=$PLAN_DATABASE.new

if [ -f $DB_FILE ]; then
	rm -rf $DB_FILE
fi

plan_read_lines "plan_get_line_from_range $TIME_NOW $TIME_END" | while read LINE; do
	echo $LINE >> $DB_FILE
done

mv $DB_FILE $PLAN_DATABASE
