# build monthly archives
build_montharchive(){
	export CACHE_TYPE=month
	[ ! -z "$MONTHARCH_DATATYPE" ] &&
		ARCH_DATATYPE="$MONTHARCH_DATATYPE"
	query_db "$month"
	if [ ! -z "${DB_RESULTS[*]}" ]; then
		LOOPMONTH_LIST=(${DB_RESULTS[*]})
		[ "$NB_QUERY" != all ] &&
			LOOPMONTH_LIST=(`for update_entry in ${UPDATE_LIST[@]}; do \
				for month_entry in ${DB_RESULTS[@]}; do echo $month_entry; done \
					|grep "$update_entry"; done`)
		set_monthlink "$month"
		set_monthnavlinks "$month"
		set_baseurl "" "$BLOG_DIR/$ARCHIVES_DIR/$month_file"
		make_archive "$month" nocat "$MONTHENTRY_TEMPLATE" "$BLOG_DIR/$PARTS_DIR/$month_file"
		NB_ArchiveTitle="$month"
		# check if make_calendar() is provided by calendar.sh plugin
		if [ ! -z $PLUGIN_CALENDAR ] && [ ! -z "$CAL_HEAD" ]; then
			make_calendar "${month:0:4}" "${month:5:6}" "$BLOG_DIR/$PARTS_DIR/$month_dir/cal.$NB_FILETYPE"
			# month calendar's place-holder for the templates
			NB_MonthlyCalendar=$(< "$BLOG_DIR/$PARTS_DIR/$month_dir/cal.$NB_FILETYPE")
			# pretty-print NB_ArchiveTitle
			NB_ArchiveTitle="$CAL_HEAD"
		fi
		paginate "$month" nocat "$MAX_MONTHPAGE_ENTRIES" "$MONTH_TEMPLATE" \
			"$MONTHENTRY_TEMPLATE" "$BLOG_DIR/$ARCHIVES_DIR/" "$month_file"
		if [ "$DAY_ARCHIVES" = 1 ]; then
			# plugins for archiving by day
			load_plugins archive/day
		fi
	fi
}

loop_archive "${LOOP_LIST[*]}" months build_montharchive

