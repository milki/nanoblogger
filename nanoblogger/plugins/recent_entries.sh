# NanoBlogger Recent Entries List Plugin
# List Recent entries
#
# sample code for templates, based off the default stylesheet
#
# <div class="sidetitle">
# Recent Entries/Alternate Entries
# </div>
# <div class="side">
# $NB_Recent_Entries/$NB_Alterate_Entries
# </div>

# set how many entries to list
: ${RECENTLIST_ENTRIES:=10}
: ${RECENTLIST_OFFSET:=1}
: ${RECENTLIST_QUERYMODE:=max}

PLUGIN_OUTFILE1="$BLOG_DIR/$PARTS_DIR/recent_entries.$NB_FILETYPE"
PLUGIN_OUTFILE2="$BLOG_DIR/$PARTS_DIR/alternate_entries.$NB_FILETYPE"

# always sort in reverse chronological order so recent entries
# stay near the top of the list
if [ "$CHRON_ORDER" != 1 ]; then
	RECENTLIST_SORTARGS="-ru"
else
	RECENTLIST_SORTARGS=
fi

nb_msg "$plugins_action recent entries links ..."
set_baseurl "./"

get_entries(){
case "$1" in
	new)
		query_db "$RECENTLIST_QUERYMODE" nocat limit "$RECENTLIST_ENTRIES" "" "$RECENTLIST_SORTARGS"
		;;
	alt)
		let XRECENTLIST_OFFSET=${RECENTLIST_ENTRIES}+1
		XRECENTLIST_ENTRIES=$RECENTLIST_ENTRIES
		query_db "$RECENTLIST_QUERYMODE" nocat limit "$XRECENTLIST_ENTRIES" "$XRECENTLIST_OFFSET" "$RECENTLIST_SORTARGS"
		;;
esac
RECENTLIST_DBRESULTS=(${DB_RESULTS[*]})
for entry in ${RECENTLIST_DBRESULTS[*]}; do
	# 1st try to get title from set_entrylink instance of read_metadata
	link_title="$smartlink_metatitle"
	if [ -z "$link_title" ]; then
		read_metadata TITLE "$NB_DATA_DIR/$entry"
		link_title="$METADATA"
	fi
	NB_EntryID=$x_id${entrylink_var//[\/]/-}
	[ -z "$link_title" ] && link_title="$notitle"
	set_entrylink "$entry"
	echo '<a href="'${ARCHIVES_PATH}$NB_EntryPermalink'">'$link_title'</a><br />'
done
}

get_entries new > "$PLUGIN_OUTFILE1"
NB_RecentEntries=$(< "$PLUGIN_OUTFILE1")

# uncomment to create alternate entry listing
#get_entries alt > "$PLUGIN_OUTFILE2"
#NB_AlternateEntries=$(< "$PLUGIN_OUTFILE2")

