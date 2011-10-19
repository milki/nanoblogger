# Nanoblogger Plugin: Weblog Links
# Last modified: 2010-02-15T01:42:38-05:00

# <div class="sidetitle">
# Links
# </div>
#
# <div class="side">
# $NB_MainLinks
# </div>

# <div class="sidetitle">
# Categories
# </div>
#
# <div class="side">
# $NB_CategoryLinks
# </div>

# <div class="sidetitle">
# Archives
# </div>
#
# <div class="side">
# $NB_MonthLinks
# </div>

# command used to filter order of category links
: ${CATLINKS_FILTERCMD:=sort}

# maximum number of months to show for $NB_MonthLinks
# -1 = all
: ${MAX_MONTHLINKS:=12}
: ${ALL_MONTHLINKS:=0}

# maximum number of years to show for $NB_YearLinks
# -1 = all
: ${MAX_YEARLINKS:=12}
: ${ALL_YEARLINKS:=0}

# validate MAX_MONTHLINKS (must be greater than 0)
MONTHLINKS_NUMVAR=`echo "$MAX_MONTHLINKS" |grep -c "[0-9]"`
[ "$MONTHLINKS_NUMVAR" = 0 ] &&
	die "MAX_MONTHLINKS !> 0"
# unlimited links
if [ "$MAX_MONTHLINKS" = -1 ]; then
	ALL_MONTHLINKS="1"
	MAX_MONTHLINKS="1"
fi

# validate MAX_YEARLINKS (must be greater than 0)
YEARLINKS_NUMVAR=`echo "$MAX_YEARLINKS" |grep -c "[0-9]"`
[ "$YEARLINKS_NUMVAR" = 0 ] &&
	die "MAX_YEARLINKS !> 0"
# unlimited links
if [ "$MAX_YEARLINKS" = -1 ]; then
	ALL_YEARLINKS="1"
	MAX_YEARLINKS="1"
fi

set_baseurl "./"
nb_msg "$plugins_action weblog links ..."
# create main set of links
load_template "$NB_TEMPLATE_DIR/$MAINLINKS_TEMPLATE"
NB_MainLinks="$TEMPLATE_DATA"

# create links for categories
build_catlinks(){
for bcat_link in ${db_categories[*]}; do
	if [ -f "$NB_DATA_DIR/$bcat_link" ]; then
		#cat_index=`chg_suffix "$bcat_link"`
		#cat_feed=`chg_suffix "$bcat_link" "$NB_SYND_FILETYPE"`
		set_catlink "$bcat_link"
		cat_index="$category_link"
		query_db "$db_query" "$bcat_link"
		cat_total=${#DB_RESULTS[*]}
		NB_CategoryTitle=`nb_print "$NB_DATA_DIR/$bcat_link" 1`
		cat <<-EOF
			<!-- $NB_CategoryTitle --><a href="${ARCHIVES_PATH}$cat_index">$NB_CategoryTitle</a> ($cat_total) <br />
		EOF
	fi
done
}

# get total number of years and tally total months from MAX_YEARLINKS
[ -z "${YEAR_DB_RESULTS[*]}" ] && query_db years
total_nyears=${#YEAR_DB_RESULTS[*]}
NYEARS=(`for nyear in ${YEAR_DB_RESULTS[*]}; do echo $nyear; done |sed "$MAX_YEARLINKS"q`)

month_tally=0
for query_nyear in ${NYEARS[*]}; do
	query_db "$query_nyear"
	months_nyear=${#DB_RESULTS[*]}
	[ "$months_nyear" -gt 0 ] &&
		let month_tally=${month_tally}+$months_nyear
done

# get total number of months and tally total entries from MAX_MONTHLINKS
[ -z "${MONTH_DB_RESULTS[*]}" ] && query_db months
total_nmonths=${#MONTH_DB_RESULTS[*]}
NMONTHS=(`for nmonth in ${MONTH_DB_RESULTS[*]}; do echo $nmonth; done |sed "$MAX_MONTHLINKS"q`)

entry_tally=0
for query_nmonth in ${NMONTHS[*]}; do
	query_db "$query_nmonth"
	entries_nmonth=${#DB_RESULTS[*]}
	[ "$entries_nmonth" -gt 0 ] &&
		let entry_tally=${entry_tally}+$entries_nmonth
done

build_catlinks |$CATLINKS_FILTERCMD |sed -e 's/<!-- .* -->//' > "$BLOG_DIR/$PARTS_DIR/cat_links.$NB_FILETYPE"
NB_CategoryLinks=$(< "$BLOG_DIR/$PARTS_DIR/cat_links.$NB_FILETYPE")
[ -z "$NB_CategoryLinks" ] && NB_CategoryLinks="$categories_nolist"

# create links to feeds
# TODO: include RSS 1.0 feeds or just forget about them?
if [[ ! -z "$NB_RSS2Ver" && ! -z "$NB_AtomVer" ]]; then
	NB_BlogFeeds="$template_syndicate_main ($NB_RSS2FeedLink, $NB_AtomFeedLink)<br />"
elif [[ ! -z "$NB_RSS2Ver" && -z "$NB_AtomVer" ]]; then
	NB_BlogFeeds="$template_syndicate_main ($NB_RSS2FeedLink)<br />"
elif [[ -z "$NB_RSS2Ver" && ! -z "$NB_AtomVer" ]]; then
	NB_BlogFeeds="$template_syndicate_main ($NB_AtomFeedLink)<br />"
fi
if [ "$CATEGORY_FEEDS" = 1 ]; then
	if [[ "$ATOM_CATFEEDS" = 1 && "$RSS2_CATFEEDS" = 1 ]]; then
		# TODO: find a better way to check if atom or rss feeds exist before adding them blindly
		sed 's@<a href="\([^"]*\)\('$NB_INDEX'\)\{'$SHOW_INDEXFILE'\}">\([^<]*\)</a>.*@\3 (<a href="\1index-rss.xml" class="feed-small">RSS</a>, <a href="\1index-atom.xml" class="feed-small">Atom</a>)<br />@' "$BLOG_DIR/$PARTS_DIR/cat_links.$NB_FILETYPE" > "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE"
		NB_CategoryFeeds=$(< "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE")
	elif [[ "$ATOM_CATFEEDS" = 1  &&  "$RSS2_CATFEEDS" != 1 ]]; then
		sed 's@<a href="\([^"]*\)\('$NB_INDEX'\)\{'$SHOW_INDEXFILE'\}">\([^<]*\)</a>.*@\3 (<a href="\1index-atom.xml" class="feed-small">Atom</a>)<br />@' "$BLOG_DIR/$PARTS_DIR/cat_links.$NB_FILETYPE" > "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE"
		NB_CategoryFeeds=$(< "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE")
	elif [[ "$RSS2_CATFEEDS" = 1 && "$ATOM_CATFEEDS" != 1 ]]; then
		sed 's@<a href="\([^"]*\)\('$NB_INDEX'\)\{'$SHOW_INDEXFILE'\}">\([^<]*\)</a>.*@\3 (<a href="\1index-rss.xml" class="feed-small">RSS</a>)<br />@' "$BLOG_DIR/$PARTS_DIR/cat_links.$NB_FILETYPE" > "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE"
		NB_CategoryFeeds=$(< "$BLOG_DIR/$PARTS_DIR/cat_feeds.$NB_FILETYPE")
	fi
fi

# helper to create links to year archives
make_yearlink(){
NB_YearTitle="$yearlink"
query_db "$yearlink"
year_total=${#DB_RESULTS[*]}
# following needs to fit on single line
cat <<-EOF
	<a href="${ARCHIVES_PATH}$yearlink/$NB_INDEX">$NB_YearTitle</a> ($year_total)<br />
EOF
}

# cal command test to retrieve locale month titles
[ -z "$CAL_CMD" ] && CAL_CMD="cal"
$CAL_CMD > "$SCRATCH_FILE".cal_test 2>&1 && CAL_VAR="1"

# tool to create monthly archive links
make_monthlink(){
if [ "$CAL_VAR" = "1" ]; then
	[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS $monthn $yearn`
	[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS $monthn $yearn`
	Month_Title=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`
else
	Month_Title="$month"
fi
month_total=${#DB_RESULTS[*]}
set_monthlink "$month"
cat <<-EOF
	<a href="${ARCHIVES_PATH}$NB_ArchiveMonthLink">$Month_Title</a> ($month_total)<br />
EOF
}

# create yearly archive links
if [ "$ALL_YEARLINKS" = 1 ]; then
	query_db all
else
	query_db all nocat limit $month_tally 1
fi
YEARLINKS_LIST=(`for yearlink in ${DB_RESULTS[*]}; do
		echo $yearlink
	done |cut -c1-4 |sort $SORT_ARGS`)
for yearlink in ${YEARLINKS_LIST[*]}; do
	make_yearlink
done |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE"
# yearly archives continued
if [ $ALL_YEARLINKS != 1 ] && [ $MAX_YEARLINKS -lt $total_nyears ]; then
	cat >> "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE" <<-EOF
		<a href="${ARCHIVES_PATH}$NB_INDEX">$NB_NextPage</a>
	EOF
fi
NB_YearLinks=$(< "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE")

# create monthly archive links
if [ "$MONTH_ARCHIVES" = 1 ]; then
	if [ "$ALL_MONTHLINKS" = 1 ]; then
		query_db all
	else
		query_db all nocat limit $entry_tally 1
	fi
	loop_archive "${DB_RESULTS[*]}" months make_monthlink |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE"
	# monthly archives continued
	if [ $ALL_MONTHLINKS != 1 ] && [ $MAX_MONTHLINKS -lt $total_nmonths ]; then
		cat >> "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE" <<-EOF
			<a href="${ARCHIVES_PATH}$NB_INDEX">$NB_NextPage</a>
		EOF
	fi
	NB_MonthLinks=$(< "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE")
fi
