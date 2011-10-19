# NanoBlogger Weblog Status Plugin
# generate some misc. statistics about the weblog
#
# sample code for templates - based on default stylesheet
#
# <div class="sidetitle">
# Weblog Status
# </div>
# <div class="side">
# $NB_Blog_Status
# </div>

OUTPUT_FILE="$BLOG_DIR/$PARTS_DIR/weblog_status.$NB_FILETYPE"
WEBLOGSTATUS_TEMPLATECOPY="$NB_BASE_DIR/default/templates/weblog_status.htm"
WEBLOG_STATUSTEMPLATE="$NB_TEMPLATE_DIR/weblog_status.htm"

nb_msg "$plugins_action weblog status ..."
if [ ! -f "$WEBLOG_STATUSTEMPLATE" ] ; then
	# WEBLOG_STATUSTEMPLATE doesn't exist, get it from default
	cp "$WEBLOGSTATUS_TEMPLATECOPY" "$WEBLOG_STATUSTEMPLATE" ||
		die "$nb_plugin: failed to copy '$WEBLOGSTATUS_TEMPLATECOPY!' please repair nanoblogger! goodbye."
fi

[ -r "$WEBLOG_STATUSTEMPLATE" ] ||
    die "`basename $0`: '$WEBLOG_STATUSTEMPLATE' - missing template! goodbye."

TOTAL_CATEGORIES=`for catdbs in "$NB_DATA_DIR"/cat_*."$NB_DBTYPE"; do echo $catdbs; done |grep -c "."`
TOTAL_ENTRIES=`grep -c "." "$NB_DATA_DIR/master.$NB_DBTYPE"`
LAST_ENTRY=`nb_print "$NB_DATA_DIR/master.$NB_DBTYPE" 1 |cut -d">" -f 1`
if [ -f "$NB_DATA_DIR/$LAST_ENTRY" ]; then
	read_metadata DATE "$NB_DATA_DIR/$LAST_ENTRY"
	LAST_ENTRY_TIME="$METADATA"
else
	LAST_ENTRY_TIME=""
fi
LAST_UPDATED=`filter_dateformat "$DATE_FORMAT"`

NB_BlogStatus=$(< "$WEBLOG_STATUSTEMPLATE")

cat > "$OUTPUT_FILE" <<-EOF
	cat <<-TMPL

		$NB_BlogStatus

	TMPL
EOF

NB_BlogStatus=$(. "$OUTPUT_FILE")

cat > "$OUTPUT_FILE" <<-EOF
	$NB_BlogStatus
EOF

