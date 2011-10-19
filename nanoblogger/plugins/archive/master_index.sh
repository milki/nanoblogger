# NanoBlogger Plugin that creates a master archive index
# in conjunction with the yearly archive indexes created
# by archive/year/year_index.sh plugin

# command used to filter order of category links
: ${CATLINKS_FILTERCMD:=sort}

# concatenate modification variables
MASTERIMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Delete_CatDBFile$Cat_EntryFile$USR_TITLE"
MASTERIMOD_QUERY=`echo "$NB_QUERY" |grep "^[0-9].*"`

# check for weblog modifications
if [ ! -z "$MASTERIMOD_VAR" ] || [ ! -z "$MASTERIMOD_QUERY" ] || [ "$NB_QUERY" = all ]; then
	nb_msg "$plugins_action archive index page ..."
	# help ease transition from 3.2.x or earlier
	YEAR_TEMPLATECOPY="$NB_BASE_DIR/default/templates/$YEAR_TEMPLATE"
	if [ ! -f "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" ] ; then
		# YEAR_TEMPLATE doesn't exist, get it from default
		cp "$YEAR_TEMPLATECOPY" "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" ||
			die "$nb_plugin: failed to copy '$YEAR_TEMPLATECOPY!' repair nanoblogger! goodbye."
	fi
	# make NB_ArchiveEntryLinks placeholder
	query_db
	set_baseurl "../"

	# create links for categories
	build_catlinks(){
	for bcat_link in ${db_categories[*]}; do
		if [ -f "$NB_DATA_DIR/$bcat_link" ]; then
			set_catlink "$bcat_link"
			cat_index="$category_link"
			query_db "$db_query" "$bcat_link"
			cat_total=${#DB_RESULTS[*]}
			NB_ArchiveCategoryTitle=`nb_print "$NB_DATA_DIR/$bcat_link" 1`
			# following needs to fit on single line
			cat <<-EOF
<!-- $NB_ArchiveCategoryTitle --><a href="${ARCHIVES_PATH}$cat_index">$NB_ArchiveCategoryTitle</a> ($cat_total) <br />
			EOF
		fi
	done
	}

	build_catlinks |$CATLINKS_FILTERCMD |sed -e 's/<!-- .* -->//' > "$SCRATCH_FILE.cat_links.$NB_FILETYPE"
	NB_ArchiveCategoryLinks=$(< "$SCRATCH_FILE.cat_links.$NB_FILETYPE")

	make_yearlink(){
	NB_ArchiveYearTitle="$yearlink"
	query_db "$yearlink"
	year_total=${#DB_RESULTS[*]}
	# following needs to fit on single line
	cat <<-EOF
		<a href="${ARCHIVES_PATH}$yearlink/$NB_INDEX">$NB_ArchiveYearTitle</a> ($year_total)<br />
	EOF
	}

	query_db all
	YEARLINKS_LIST=(`for yearlink in ${DB_RESULTS[*]}; do
			echo $yearlink
		done |cut -c1-4 |sort $SORT_ARGS`)
	for yearlink in ${YEARLINKS_LIST[*]}; do
		make_yearlink
	done |sort $SORT_ARGS > "$SCRATCH_FILE.year_links.$NB_FILETYPE"
	NB_ArchiveYearLinks=$(< "$SCRATCH_FILE.year_links.$NB_FILETYPE")

	cat_total=${#db_categories[*]}
	if [ "$cat_total" -gt 0 ]; then
		# make NB_CategoryLinks placeholder
		NB_BrowseCategoryLinks=$(
		cat <<-EOF
			<a id="category"></a>
			<strong>$template_browsecat</strong>
			<div>
				$NB_ArchiveCategoryLinks
			</div>
			<br />
		EOF
		)
	fi

	# make NB_ArchiveLinks placeholder
	cat > "$BLOG_DIR"/"$PARTS_DIR"/archive_links.$NB_FILETYPE <<-EOF
		$NB_BrowseCategoryLinks
		<a id="date"></a>
		<strong>$template_browsedate</strong>
		<div>
			$NB_ArchiveYearLinks
		</div>
	EOF

	NB_ArchiveLinks=$(< "$BLOG_DIR/$PARTS_DIR/archive_links.$NB_FILETYPE")
	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/$NB_INDEXFILE"
	# set title for makepage template
	MKPAGE_TITLE="$template_archives"
	MKPAGE_CONTENT="$NB_ArchiveLinks"
	ARCHIVE_INDEX_TEMPLATECOPY="$NB_BASE_DIR/default/templates/archive_index.htm"
	ARCHIVE_INDEX_TEMPLATE="$NB_TEMPLATE_DIR/archive_index.htm"
	if [ ! -f "$ARCHIVE_INDEX_TEMPLATE" ] ; then
		# ARCHIVE_INDEX_TEMPLATE does not exist, get it from default
		cp "$ARCHIVE_INDEX_TEMPLATECOPY" "$ARCHIVE_INDEX_TEMPLATE" ||
			die "$nb_plugin: failed to copy '$ARCHIVE_INDEX_TEMPLATE'! please repair nanoblogger! goodbye/"
	fi
	[ -r "$ARCHIVE_INDEX_TEMPLATE" ] ||
		die "`basename $0`: '$ARCHIVE_INDEX_TEMPLATE' - missing template! goodbye."
	make_page "$BLOG_DIR/$PARTS_DIR"/archive_links.$NB_FILETYPE "$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE" "$MKPAGE_OUTFILE"
fi

