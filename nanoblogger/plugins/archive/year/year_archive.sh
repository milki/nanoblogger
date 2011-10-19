# NanoBlogger Plugin that creates yearly archive indexes

# concatenate modification variables
YEARIMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Cat_EntryFile$USR_TITLE"

build_yeararchive(){
	query_db "$yearn"
	YEARIMOD_QUERY=`echo "$NB_QUERY" |grep "^$yearn"`
	# check for weblog modifications
	if [ ! -z "$YEARIMOD_VAR" ] || [ ! -z "$YEARIMOD_QUERY" ] || [ "$NB_QUERY" = all ] || [ ! -z "$UPDATE_LIST" ]; then
		# set previous and next links for given year
		set_yearnavlinks(){
		yearnavlinks_var=${1//[\/]/-}
		year_id=
		[ ! -z "$yearnavlinks_var" ] &&
			year_id=`lookup_id "$yearnavlinks_var" "${YEAR_DB_RESULTS[*]}"`
		if [ ! -z "$year_id" ] && [ $year_id -ge 0 ]; then
			# adjust for bash array - 1 = 0
			((year_id--))
			# determine direction based on chronological date order
			if [ "$CHRON_ORDER" = 1 ]; then
				let prev_yearid=${year_id}+1
				let next_yearid=${year_id}-1
			else
				let prev_yearid=${year_id}-1
				let next_yearid=${year_id}+1
			fi	
			prev_year=; NB_PrevArchiveYearLink=
			[ $prev_yearid -ge 0 ] &&
				prev_year=${YEAR_DB_RESULTS[$prev_yearid]}
			if [ ! -z "$prev_year" ]; then
				prev_year_dir=${prev_year//[-]//}
				prev_year_file="$prev_year_dir/$NB_INDEXFILE"
				NB_PrevArchiveYearLink="$prev_year_dir/$NB_INDEX"
			fi
			next_year=; NB_NextArchiveYearLink=
			[ $next_yearid -ge 0 ] &&
				next_year=${YEAR_DB_RESULTS[$next_yearid]}
			if [ ! -z "$next_year" ]; then
				next_year_dir=${next_year//[-]//}
				next_year_file="$next_year_dir/$NB_INDEXFILE"
				NB_NextArchiveYearLink="$next_year_dir/$NB_INDEX"
			fi
		fi
		}

		[ "$pluginyearindex_msg" != 1 ] &&
			nb_msg "$plugins_action year archives ..." && pluginyearindex_msg=1
		# make NB_ArchiveEntryLinks placeholder
		set_baseurl "../../"

		ARCHENTRY_LIST=${DB_RESULTS[*]}
		NB_ArchiveEntryLinks=$(
		for entry in ${ARCHENTRY_LIST[*]}; do
			NB_EntryID=$x_id${entrylink_var//[\/]/-}
			set_entrylink "$entry"
			# 1st try to get title from set_entrylink instance of read_metadata
			NB_ArchiveEntryTitle="$smartlink_metatitle"
			if [ -z "$NB_ArchiveEntryTitle" ]; then
				read_metadata TITLE "$NB_DATA_DIR/$entry"
				NB_ArchiveEntryTitle="$METADATA"
			fi
			[ -z "$NB_ArchiveEntryTitle" ] && NB_ArchiveEntryTitle="$notitle"
			set_monthlink "$month"
			if [ "$SHOW_CATLINKS" = 1 ];then
				# Command to help filter order of categories
				: ${CATLINKS_FILTERCMD:=sort}
				>"$SCRATCH_FILE".cat_links
				entry_wcatids=`grep "$entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
				entry_catids=${entry_wcatids##*\>}
				[ "$entry_wcatids" = "$entry_catids" ] &&
					entry_catids=
				for entry_catnum in ${entry_catids//\,/ }; do
					cat_title=`nb_print "$NB_DATA_DIR"/cat_"$entry_catnum.$NB_DBTYPE" 1`
					set_catlink cat_"$entry_catnum.$NB_DBTYPE"
					cat_index="$category_link"
					# following must fit on single line
					$CATLINKS_FILTERCMD  >> "$SCRATCH_FILE".cat_links <<-EOF
						<!-- $cat_title --><a href="${ARCHIVES_PATH}$cat_index">$cat_title</a>,
					EOF
				done
				NB_EntryCategories=$(< "$SCRATCH_FILE.cat_links")
				NB_EntryCategories="${NB_EntryCategories%%,}"
			fi
			if [ "$MONTH_ARCHIVES" = 1 ]; then
				yearindex_monthlink='<a href="'${ARCHIVES_PATH}$NB_ArchiveMonthLink'">'$month'</a>'
			else
				yearindex_monthlink="$month"
			fi
			cat <<-EOF
				$yearindex_monthlink
				- <a href="${ARCHIVES_PATH}$NB_EntryPermalink">$NB_ArchiveEntryTitle</a>
				$([ ! -z "$NB_EntryCategories" ] && echo "- $NB_EntryCategories")<br />
			EOF
		done; month=
		)

		# create links for monthly archives
		[ -z "$CAL_CMD" ] && CAL_CMD="cal"
		nb_eval "$CAL_CMD" && CAL_VAR="1"
			
		make_monthlink(){
		if [ "$CAL_VAR" = "1" ]; then
			[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS $monthn $yearn`
			[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS $monthn $yearn`
			CAL_HEAD=`echo "$CALENDAR" |sed 1q`
			CAL_HEAD=${CAL_HEAD//[ ][ ]/}; NB_ArchiveMonthTitle=${CAL_HEAD%%[ ][ ]}; NB_ArchiveMonthTitle=${CAL_HEAD##[ ][ ]}
		else
			NB_ArchiveMonthTitle="$month"
		fi
		month_total=${#DB_RESULTS[*]}
		set_monthlink "$month"
		# following needs to fit on single line
		cat <<-EOF
			<a href="${ARCHIVES_PATH}$NB_ArchiveMonthLink">$NB_ArchiveMonthTitle</a> ($month_total)<br />
		EOF
		}

		[ -z "${YEAR_DB_RESULTS[*]}" ] && query_db years
		set_yearnavlinks "$yearn"
		if [ "$MONTH_ARCHIVES" = 1 ]; then
			loop_archive "${DB_RESULTS[*]}" months make_monthlink |sort $SORT_ARGS \
				> "$SCRATCH_FILE.$yearn-month_links.$NB_FILETYPE"
			NB_ArchiveMonthLinks=$(< "$SCRATCH_FILE.$yearn-month_links.$NB_FILETYPE")
			yearindex_monthbrowse='<a id="date"></a><strong>'$template_browsedate'</strong>'
		fi

		# make NB_ArchiveLinks placeholder
		mkdir -p `dirname "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE"`
		cat > "$BLOG_DIR"/"$PARTS_DIR"/"$yearn"/archive_links.$NB_FILETYPE <<-EOF
			$yearindex_monthbrowse
			<div>
				$NB_ArchiveMonthLinks
			</div>
			<br />
			<a id="entry"></a><strong>$template_browseentry</strong>
			<div>
				$NB_ArchiveEntryLinks
			</div>
		EOF

		NB_ArchiveLinks=$(< "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE")
		# build master archive index
		MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/$yearn/$NB_INDEXFILE"
		# set title for makepage template
		MKPAGE_TITLE="$yearn $template_archives"
		MKPAGE_CONTENT="$NB_ArchiveLinks"
		make_page "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE" "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" "$MKPAGE_OUTFILE"
	fi
}

loop_archive "${LOOP_LIST[*]}" years build_yeararchive

