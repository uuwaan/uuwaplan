#!/bin/bash
source `dirname $0`/libplan.sh

TIME_NOW=`date +%Y%m%d`
TIME_END=`date -d "-$(date +%d) days +100 year" +%Y%m%d`
DB_FILE=$PLAN_DATABASE.new

if [[ -a "$DB_FILE" ]]; then
	rm -f "$DB_FILE"
fi

plan_read_lines | plan_filter_by_date $TIME_NOW $TIME_END | while read LINE; do
	echo $LINE >> "$DB_FILE"
done

mv "$DB_FILE" "$PLAN_DATABASE"
