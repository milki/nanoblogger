# build daily archives
build_dayarchive(){
	export CACHE_TYPE=day
	[ ! -z "$DAYARCH_DATATYPE" ] &&
		ARCH_DATATYPE="$DAYARCH_DATATYPE"
	query_db "$day"
	if [ ! -z "${DB_RESULTS[*]}" ]; then
		set_daylink "$day"
		set_daynavlinks "$day"
		set_baseurl "" "$BLOG_DIR/$ARCHIVES_DIR/$day_file"
		make_archive "$day" nocat "$DAYENTRY_TEMPLATE" "$BLOG_DIR/$PARTS_DIR/$day_file"
		NB_ArchiveTitle="$day_dir"
		dayn=${day:8:2}
		
		# pretty-print daily archive title, replaces $NB_ArchiveTitle
		if [ ! -z $PLUGIN_CALENDAR ] && [ ! -z "$CAL_HEAD" ]; then
			DayMonthTitle=${CAL_HEAD//$yearn/}
			DayMonthTitle=${DayMonthTitle// }
			NB_ArchiveTitle="$DayMonthTitle $dayn, $yearn"
		fi

		make_page "$BLOG_DIR/$PARTS_DIR/$day_file" "$NB_TEMPLATE_DIR/$DAY_TEMPLATE" \
		"$BLOG_DIR/$ARCHIVES_DIR/$day_file"
	fi
}

loop_day(){
	loopday_list=($1)
	loopday_exec="$2"
	LOOP_MASTER=(${loopday_list[*]})
	ARCHIVE_DAYS=(`for db_item in ${LOOP_MASTER[@]}; do echo $db_item; done |cut -c1-10 |sort $SORT_ARGS`)
	for dayn in ${ARCHIVE_DAYS[@]}; do
		day="$dayn"
		query_db "$day"
		[ ! -z "${DB_RESULTS[*]}" ] && [ ! -z "$loopday_exec" ] &&
			$loopday_exec
	done
}

loop_day "${LOOPMONTH_LIST[*]}" build_dayarchive

