# Module for archive functions
# Last modified: 2008-07-16T22:54:53-04:00

# set base url based on parameters
set_baseurl(){
node_var="$1"
base_dir=`dirname "$2"`
# check if we want absolute links
if [ "$ABSOLUTE_LINKS" = 1 ]; then
	BASE_URL="$BLOG_URL/"
else
	BASE_URL="$node_var"
	if [ "$base_dir" != . ]; then
		blogdir_sedvar=`echo "${BLOG_DIR//\//\\\\/}\\\\/"`
		base_dir="$base_dir/./"
		BASE_URL=`echo "$base_dir" |sed -e 's/'$blogdir_sedvar'//g; /^[\.]\// s///; s/[^ \/]*./..\//g; s/^[\.][\.]\///g'`
	fi
	[ -z "$BASE_URL" ] && BASE_URL="./"
fi
# set link path to archives
ARCHIVES_PATH="${BASE_URL}$ARCHIVES_DIR/"
}

# set link/file for given category
set_catlink(){
catlink_var="$1"
# title-based links
category_title=`nb_print "$NB_DATA_DIR/$catlink_var" 1`
category_dir=`set_smartlinktitle "$catlink_var" cat`
# failsafe for setting cat directories
: ${category_dir:=${catlink_var%%\.*}}
category_file="$category_dir/$NB_INDEXFILE"
category_link="$category_dir/$NB_INDEX"
}

# set link/file for given month
set_monthlink(){
month_dir="${1//\-//}"
month_file="$month_dir/$NB_INDEXFILE"
NB_ArchiveMonthLink="$month_dir/$NB_INDEX"
}

set_daylink(){
day_dir="${1//\-//}"
day_file="$day_dir/$NB_INDEXFILE"
NB_ArchiveDayLink="$day_dir/$NB_INDEX"
}

set_daynavlinks(){
daynavlinks_var="${1//\//-}"
day_id=
[ ! -z "$daynavlinks_var" ] &&
	day_id=`lookup_id "$daynavlinks_var" "${DAY_DB_RESULTS[*]}"`
if [ ! -z "$day_id" ] && [ $day_id -gt 0 ]; then
	# adjust for bash array - 1 = 0
	((day_id--))
	# determine direction based on chronological date order
	if [ "$CHRON_ORDER" = 1 ]; then
		let prev_dayid=${day_id}+1
		let next_dayid=${day_id}-1
	else
		let prev_dayid=${day_id}-1
		let next_dayid=${day_id}+1
	fi
	prev_day=; NB_PrevArchiveDayLink=
	[ $prev_dayid -ge 0 ] &&
		prev_day=${DAY_DB_RESULTS[$prev_dayid]}
	if [ ! -z "$prev_day" ]; then
		prev_day_dir="${prev_day//\-//}"
		prev_day_file="$prev_day_dir/$NB_INDEXFILE"
		NB_PrevArchiveDayLink="$prev_day_dir/$NB_INDEX"
	fi
	next_day=; NB_NextArchiveDayLink=
	[ $next_dayid -ge 0 ] &&
		next_day=${DAY_DB_RESULTS[$next_dayid]}
	if [ ! -z "$next_day" ]; then
		next_day_dir="${next_day//\-//}"
		next_day_file="$next_day_dir/$NB_INDEXFILE"
		NB_NextArchiveDayLink="$next_day_dir/$NB_INDEX"
	fi
fi
}

# set previous and next links for given month
set_monthnavlinks(){
monthnavlinks_var="${1//\//-}"
month_id=
[ ! -z "$monthnavlinks_var" ] &&
	month_id=`lookup_id "$monthnavlinks_var" "${MONTH_DB_RESULTS[*]}"`
if [ ! -z "$month_id" ] && [ $month_id -gt 0 ]; then
	# adjust for bash array - 1 = 0
	((month_id--))
	# determine direction based on chronological date order
	if [ "$CHRON_ORDER" = 1 ]; then
		let prev_monthid=${month_id}+1
		let next_monthid=${month_id}-1
	else
		let prev_monthid=${month_id}-1
		let next_monthid=${month_id}+1
	fi
	prev_month=; NB_PrevArchiveMonthLink=
	[ $prev_monthid -ge 0 ] &&
		prev_month=${MONTH_DB_RESULTS[$prev_monthid]}
	if [ ! -z "$prev_month" ]; then
		prev_month_dir="${prev_month//\-//}"
		prev_month_file="$prev_month_dir/$NB_INDEXFILE"
		NB_PrevArchiveMonthLink="$prev_month_dir/$NB_INDEX"
	fi
	next_month=; NB_NextArchiveMonthLink=
	[ $next_monthid -ge 0 ] &&
		next_month=${MONTH_DB_RESULTS[$next_monthid]}
	if [ ! -z "$next_month" ]; then
		next_month_dir="${next_month//\-//}"
		next_month_file="$next_month_dir/$NB_INDEXFILE"
		NB_NextArchiveMonthLink="$next_month_dir/$NB_INDEX"
	fi
fi
}

# generate entry's anchor/id
set_entryid(){
echo "$x_id${1//[\/]/-}"
}

# use instead of translit_text to avoid file/URL collissions
set_smartlinktitle(){
altlink_var="$1"
altlink_type="$2"
case "$altlink_type" in
	entry)
		[ -f "$NB_DATA_DIR/$altlink_var" ] &&
			read_metadata TITLE "$NB_DATA_DIR/$altlink_var"
		smartlink_metatitle="$METADATA"
		altentry_linktitle=`translit_text "$METADATA"`
		# search for similar titles that fall on same day
		alte_day=${altlink_var:0:10}
		query_db "$alte_day"
		ALTLINK_LIST=(${DB_RESULTS[*]})
		if [ "${#ALTLINK_LIST}" -gt 1 ]; then
			for alte in ${ALTLINK_LIST[*]}; do
				[ -f "$NB_DATA_DIR/$alte" ] &&
					read_metadata TITLE "$NB_DATA_DIR/$alte"
				alte_linktitle=`translit_text "$METADATA"`
				# entry title failsafe
				[ -z "$alte_linktitle" ] &&
					alte_linktitle=`translit_text "$notitle"`
				echo "$alte:$alte_linktitle"
			done |sort $SORT_ARGS > "$SCRATCH_FILE".altlinks
		fi
		link_match="$altentry_linktitle"
		alte_backup=${altlink_var//-//}; alte_backup=${alte_backup//T//T}
		alte_backup=${alte_backup%%.*}; altlink_backup="${alte_backup//*\/}"
		;;
	cat)
		[ -f "$NB_DATA_DIR/$altlink_var" ] &&
			altcat_title=`nb_print "$NB_DATA_DIR/$altlink_var" 1`
		altcat_linktitle=`translit_text "$altcat_title"`
		query_db # get categories list
		ALTLINK_LIST=(${db_categories[*]})
		for altt in ${ALTLINK_LIST[*]}; do
			[ -f "$NB_DATA_DIR/$altt" ] &&
				altt_title=`nb_print "$NB_DATA_DIR/$altt" 1`
			altt_linktitle=`translit_text "$altt_title"`
			# cat title failsafe
			[ -z "$altt_linktitle" ] &&
				altt_linktitle=`translit_text "$notitle"`
			echo "$altt:$altt_linktitle"
		done |sort $SORT_ARGS > "$SCRATCH_FILE".altlinks
		link_match="$altcat_linktitle"
		altlink_backup=${altlink_var%%\.*}
		;;
esac
[ ! -f "$SCRATCH_FILE".altlinks ] && > "$SCRATCH_FILE".altlinks
# link match failsafe
[ -z "$link_match" ] &&
	link_match=`translit_text "$notitle"`
get_linkconflicts(){
	linkmatch_var="$1"
	if [ ! -z "$linkmatch_var" ]; then
		grep -c ":${linkmatch_var}$" "$SCRATCH_FILE".altlinks
	else
		echo 0
	fi
	}
TOTAL_LINKCFLICTS=`get_linkconflicts "$link_match"`
ALTLINK_LIST=(`cut -d":" -f 1 "$SCRATCH_FILE".altlinks`)
altli=0
while [ "$TOTAL_LINKCFLICTS" -gt 1 ]; do
	for altl in ${ALTLINK_LIST[*]}; do
		altl_match=`grep -c ":${link_match}$" "$SCRATCH_FILE".altlinks`
		if [ "$altl_match" -gt 1 ]; then
			let altli=${altl_match}-1
			sed -e '/'$altl':*.*/ s//'$altl':'$link_match'_'${altli}'/' "$SCRATCH_FILE".altlinks > "$SCRATCH_FILE".altlinks.new
			mv "$SCRATCH_FILE".altlinks.new "$SCRATCH_FILE".altlinks
		else
			altli=0 # reset counter
		fi
	done
	TOTAL_LINKCFLICTS=`get_linkconflicts "$link_match"`
done
smart_linktitle=`sed -e '/'$altlink_var':/!d; /'$altlink_var':/ s///' "$SCRATCH_FILE".altlinks`
# smart linktitle failsafe and backwards compatibility
[ -z "$smart_linktitle" ] || [ "$FRIENDLY_LINKS" != 1 ] &&
	smart_linktitle="$altlink_backup"
echo "$smart_linktitle"
}

# set link/file for given entry
set_entrylink(){
entrylink_var="$1"
link_type="$2"
if [ "$ENTRY_ARCHIVES" = 1 ] && [ "$link_type" != altlink ]; then
	entrylink_var="${entrylink_var//-//}"
	entry_dir=${entrylink_var%%\.*}
	entry_dir=${entry_dir:0:10}
	entry_linktitle=`set_smartlinktitle "${entrylink_var//\//-}" entry`
	permalink_file="$entry_dir/$entry_linktitle/$NB_INDEXFILE"
	NB_EntryPermalink="$entry_dir/$entry_linktitle/$NB_INDEX"

	month=${entrylink_var:0:7}
	set_monthlink "$month"
	day=${entrylink_var:0:10}
	set_daylink "$day"
else
	month=${entrylink_var:0:7}
	set_monthlink "$month"
	entrylink_id=$x_id${entrylink_var//[\/]/-}
	NB_EntryPermalink="$NB_ArchiveMonthLink#$entrylink_id"
	if [ "$DAY_ARCHIVES" = 1 ]; then
		day=${entrylink_var:0:10}
		set_daylink "$day"
		NB_EntryPermalink="$NB_ArchiveDayLink#$entrylink_id"
	fi
fi
}

# set previous and next links for given entry
set_entrynavlinks(){
entrynavlinks_type="$1"
entrynavlinks_entry=`echo "$2" |grep '^[0-9].*'`
case "$entrynavlinks_type" in
	prev)
		prev_entry=; NB_PrevEntryPermalink=
		prev_entry="$entrynavlinks_entry"
		;;
	next)
		next_entry=; NB_NextEntryPermalink=
		next_entry="$entrynavlinks_entry"
		;;
esac
if [ ! -z "$prev_entry" ]; then
	# Nijel: support for named permalinks
	prev_entrylink_var=${prev_entry//[-]//}
	prev_entry_file="${prev_entrylink_var##*.}"
	prev_entry_dir=${prev_entrylink_var%%\.*}
	prev_entry_dir=${prev_entry_dir:0:10}
	prev_entry_linktitle=`set_smartlinktitle "$prev_entry" entry`
	prev_permalink_file="$prev_entry_dir/$prev_entry_linktitle/$NB_INDEXFILE"
	NB_PrevEntryPermalink="$prev_entry_dir/$prev_entry_linktitle/$NB_INDEX"
fi
if [ ! -z "$next_entry" ]; then
	# Nijel: support for named permalinks
	next_entrylink_var=${next_entry//[-]//}
	next_entry_file="${next_entrylink_var##*.}"
	next_entry_dir=${next_entrylink_var%%\.*}
	next_entry_dir=${next_entry_dir:0:10}
	next_entry_linktitle=`set_smartlinktitle "$next_entry" entry`
	next_permalink_file="$next_entry_dir/$next_entry_linktitle/$NB_INDEXFILE"
	NB_NextEntryPermalink="$next_entry_dir/$next_entry_linktitle/$NB_INDEX"
fi
}

# create entry archive
make_entryarchive(){
if [ "$ENTRY_ARCHIVES" = 1 ]; then
	mkdir -p `dirname "$BLOG_DIR/$PARTS_DIR/$permalink_file"`
	write_template > "$BLOG_DIR/$PARTS_DIR/$permalink_file"
	make_page "$BLOG_DIR/$PARTS_DIR/$permalink_file" "$NB_TEMPLATE_DIR/$PERMALINK_TEMPLATE" \
	"$BLOG_DIR/$ARCHIVES_DIR/$permalink_file"
fi
}

# build entry archives
build_entryarchives(){
ENTRYARCHIVES_LIST=($1)
ENTRYARCHIVES_TEMPLATE="$2"
ENTRYARCHIVES_DATATYPE="$3"
: ${CACHE_TYPE:=entry}
for entry in ${ENTRYARCHIVES_LIST[@]}; do
	entry=${entry%%>*}
	if [ -f "$NB_DATA_DIR/$entry" ]; then
		[ -z "$PARTS_FILE" ] &&
			PARTS_FILE="$BLOG_DIR/$PARTS_DIR/$permalink_file"
		if [ "$ENTRYARCHIVES_TEMPLATE" = "$PERMALINKENTRY_TEMPLATE" ]; then
			set_baseurl "" "$BLOG_DIR/$ARCHIVES_DIR/$permalink_file"
			set_entrylink "$entry"
			load_entry "$NB_DATA_DIR/$entry" "$ENTRYARCHIVES_DATATYPE" "$CACHE_TYPE"
			year=${month:0:4}
			month=${month:5:2}
			day=${entry:8:2}
			findba_entries "$entry" "${MASTER_DB_RESULTS[*]}"
			set_entrynavlinks prev "$before_entry"
			set_entrynavlinks next "$after_entry"
			load_template "$NB_TEMPLATE_DIR/$ENTRYARCHIVES_TEMPLATE"
			make_entryarchive
		else
			set_baseurl "$BASE_URL"
			set_entrylink "$entry"
			load_entry "$NB_DATA_DIR/$entry" "$ENTRYARCHIVES_DATATYPE"
			load_template "$NB_TEMPLATE_DIR/$ENTRYARCHIVES_TEMPLATE"
			if [ ! -z "$TEMPLATE_DATA" ]; then
				mkdir -p `dirname "$PARTS_FILE"`
				write_template >> "$PARTS_FILE"
			fi
		fi
	fi
done
}

# generate archive content
make_archive(){
query_type="$1"
db_catquery="$2"
MKARCH_ENTRY_TEMPLATE="$3"
PARTS_FILE="$4"
db_setlimit="$5"
db_limit="$6"
db_offset="$7"
query_db "$query_type" "$db_catquery" "$db_setlimit" "$db_limit" "$db_offset"
ARCHIVE_LIST=(); ARCHIVE_LIST=(${DB_RESULTS[@]})
mkdir -p `dirname "$PARTS_FILE"`
> "$PARTS_FILE"
# fallback to default entry template
[ ! -f "$NB_TEMPLATE_DIR/$MKARCH_ENTRY_TEMPLATE" ] &&
	MKARCH_ENTRY_TEMPLATE="$ENTRY_TEMPLATE"
build_entryarchives "${ARCHIVE_LIST[*]}" "$MKARCH_ENTRY_TEMPLATE" "$ARCH_DATATYPE"
db_setlimit=; db_limit=; db_offset=
}

# divide larger archives into multiple pages
paginate(){
page_query="$1"
page_catquery="$2"
page_items="$3"
page_template="$4"
page_entrytemplate="$5"
page_dir="$6"
page_file="$7"
page_fbasedir=`dirname "$page_file"`
if [ "$page_fbasedir" != . ]; then
	page_filedir="$page_fbasedir/"
	page_file=`basename "$page_file"`
fi
	update_pages(){
		build_pagelist(){
		if [ ! -z "$page_num" ]; then
			[ -z "$PAGE_LIST" ] && PAGE_LIST="page$page_num"
			[ "$PAGE_LIST" != "$OLD_PAGELIST" ] && PAGE_LIST="${OLD_PAGELIST//page$page_num/} page$page_num"
			OLD_PAGELIST="$PAGE_LIST"
		fi
		}
		query_db "$page_query" "$page_catquery" limit "$page_limit" "$page_offset"
		PAGEMOD_VAR="$New_EntryFile$Delete_EntryFile$DeleteCatDBFile$Cat_EntryFile"
		for page_entry in ${UPDATE_LIST[@]}; do
			if [ ! -z "$PAGEMOD_VAR" ] || [ "$NB_QUERY" = all ] || [ "$page_catquery" = nocat ]; then
				build_pagelist
			else
				[[ ${DB_RESULTS[*]} == *$page_entry* ]] && build_pagelist
			fi
		done
		PAGE_LIST=`for page_n in $PAGE_LIST; do echo "$page_n"; done`
	}
	page_bynumber(){
	set_baseurl "" "${page_dir}${page_filedir}$page_file"
	make_archive "$page_query" "$page_catquery" "$page_entrytemplate" \
		"$BLOG_DIR/$PARTS_DIR/${page_filedir}$arch_file" limit "$page_limit" "$page_offset"
	make_page "$BLOG_DIR/$PARTS_DIR/${page_filedir}$arch_file" \
		"$NB_TEMPLATE_DIR/$page_template" "${page_dir}${page_filedir}$arch_file"
	}
query_db "$page_query" "$page_catquery"
total_items=${#DB_RESULTS[*]}
if [ "$total_items" -gt "$page_items" ] && [ "$page_items" != 0 ]; then
	get_pages(){ y=0; page_totals=($(while [ "$y" -lt "$total_items" ]; do \
		let y=${page_items}+$y; echo $y; done)); echo ${#page_totals[*]}; }
	total_pages=`get_pages`; page_totals=0
	# cleanup numbered page(s)
	if [ "$NB_QUERY" = all ]; then
		rm -f "${page_dir}${page_filedir}${page_file%%\.$NB_FILETYPE}"*[0-9]."$NB_FILETYPE"
		nb_msg "$paginate_action $total_pages ($page_items/$total_items) ..."
	else
		nb_msg "$paginate_action ($page_items/$total_items) ..."
	fi
	page_limit=0; page_offset=1; page_num=0
	while [ "$page_num" -lt "$total_pages" ]; do
		let page_totals=${page_items}+$page_totals
		let page_offset=${page_offset}+$page_limit
		# if page items overflow, use difference to set new limit
		if [ "$page_totals" -ge "$total_items" ]; then
			let page_diff=${page_totals}-$total_items
			let page_limit=${page_limit}-$page_diff
		else
			page_limit="$page_items"
		fi
		let page_num=${page_num}+1
		let prev_num=${page_num}-1
		let next_num=${page_num}+1
		arch_file="$page_file"
		arch_link="./$NB_INDEX"
		arch_name="${page_file%%\.*}"
		prev_page=`chg_suffix "$arch_name-page$prev_num".no`
		next_page=`chg_suffix "$arch_name-page$next_num".no`
		[ "$page_num" -gt 1 ] &&
			arch_file=`chg_suffix "$arch_name-page$page_num".no`
		echo '<table border="0" cellspacing="1" cellpadding="3" summary="page-menu">' > "$SCRATCH_FILE"
		echo '<tr>' >> "$SCRATCH_FILE"
		[ "$prev_num" = 1 ] &&
			echo '<td><a href="'$arch_link'">'$NB_PrevPage'</a></td>' >> "$SCRATCH_FILE"
		[ "$prev_num" -gt 1 ] &&
			echo '<td><a href="'$prev_page'">'$NB_PrevPage'</a></td>' >> "$SCRATCH_FILE"
		i=1
		while [ $i -le $total_pages ]; do
			[ "$i" = 1 ] && page="$arch_link" ||
				page=`chg_suffix "$arch_name-page$i".no`
			if [ "$i" = "$page_num" ]; then
				echo '<td>'$i'</td>' >> "$SCRATCH_FILE"
			else
				echo '<td><a href="'$page'">'$i'</a></td>' >> "$SCRATCH_FILE"
			fi
			let i=${i}+1
		done
		! [ "$next_num" -gt "$total_pages" ] &&
				echo '<td><a href="'$next_page'">'$NB_NextPage'</a></td>' >> "$SCRATCH_FILE"
		echo '</tr>' >> "$SCRATCH_FILE"; echo '</table>' >> "$SCRATCH_FILE"
		NB_PageLinks=$(< "$SCRATCH_FILE")
		if [ ! -z "${UPDATE_LIST[*]}" ] || [ ! -z "$NB_QUERY" ]; then
			update_pages
			for page_mod in ${PAGE_LIST[@]}; do
				[ "page$page_num" = "$page_mod" ] && page_bynumber
			done
		else
			page_bynumber
		fi
		NB_PageLinks=
	done
else
	set_baseurl "" "${page_dir}${page_filedir}$page_file"
	make_archive "$page_query" "$db_catquery" "$page_entrytemplate" "$BLOG_DIR/$PARTS_DIR/${page_filedir}$page_file"
	make_page "$BLOG_DIR/$PARTS_DIR/${page_filedir}$page_file" "$NB_TEMPLATE_DIR/$page_template" \
		"${page_dir}${page_filedir}$page_file"
fi
ARCH_DATATYPE=; page_filedir=
}

# build category archives
build_catarchives(){
export CACHE_TYPE=cat
if [ ! -z "${CAT_LIST[*]}" ]; then
	for cat_arch in ${CAT_LIST[@]}; do
		if [ -f "$NB_DATA_DIR/$cat_arch" ]; then
			NB_ArchiveTitle=`nb_print "$NB_DATA_DIR/$cat_arch" 1`
			set_catlink "$cat_arch"
			[ ! -z "$CATARCH_DATATYPE" ] &&
				ARCH_DATATYPE="$CATARCH_DATATYPE"
			load_plugins archive/category
			paginate all "$cat_arch" "$MAX_CATPAGE_ENTRIES" "$CATEGORY_TEMPLATE" \
				"$CATENTRY_TEMPLATE" "$BLOG_DIR/$ARCHIVES_DIR/" "$category_file"
		fi
	done
fi
}

# loops through archives, and executes instructions by years or months
loop_archive(){
looparch_list=($1)
looparch_type="$2"
looparch_exec="$3"
# set instructions to execute based on $looparch_type
case $looparch_type in
	years) looparchexec_years="$looparch_exec";;
	months) looparchexec_months="$looparch_exec";;
esac
ARCHIVE_MASTER=(); ARCHIVE_YEARS=()
ARCHIVE_MASTER=(${looparch_list[*]})
ARCHIVE_YEARS=(`for db_item in ${ARCHIVE_MASTER[@]}; do echo $db_item; done |cut -c1-4 |sort $SORT_ARGS`)
for yearn in ${ARCHIVE_YEARS[@]}; do
	# execute instructions for each year
	if [ "$looparch_type" = years ] && [ ! -z "$looparchexec_years" ]; then
		$looparchexec_years
	else
		for monthn in 12 11 10 09 08 07 06 05 04 03 02 01; do
			ARCHIVE_MONTHS=(`for db_item in ${ARCHIVE_MASTER[@]}; do echo $db_item; done |grep $yearn'[-]'$monthn'[-]' |sed 1q`)
			for entry_month in ${ARCHIVE_MONTHS[@]}; do
				year="$yearn"
				month="$yearn-$monthn"
				query_db "$month"
				# execute instructions for each month
				if [ ! -z "${DB_RESULTS[*]}" ]; then
					[ ! -z "$looparchexec_months" ] &&
						$looparchexec_months
				fi
			done
		done
	fi
done
}

# generate the archives
build_archives(){
LOOP_LIST=()
load_plugins archive
nb_msg "$buildarchives_action"
# build/update the category archives
build_catarchives
if [ "$NB_QUERY" = all ]; then
	LOOP_LIST=(${UPDATE_LIST[*]})
else
	# remove duplicate entries and category indices from update list, then sort into chronological order
	LOOP_LIST=(`for moditem in ${UPDATE_LIST[@]}; do echo ${moditem%%>*}; done |sort $SORT_ARGS`)
fi
# plugins for yearly archives
load_plugins archive/year
# plugins month and day archives
[ "$MONTH_ARCHIVES" = 1 ] &&
	load_plugins archive/month
# build entry archives
export CACHE_TYPE=entry
[ "$ENTRY_ARCHIVES" = 1 ] &&
	build_entryarchives "${UPDATE_LIST[*]}" "$PERMALINKENTRY_TEMPLATE" ALL
}

