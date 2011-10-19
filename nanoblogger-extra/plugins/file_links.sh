# NanoBlogger File Links plugin

# How it works:
# Looks for files that match *.$FILELINKS_SUFFIX in multiple directories
# and automagically creates a nice index of links for them.
# 
# Useless? You decide.
#
# Reads alternate title for list from $FILELINKS_TITLE_FILE (1st line).
# Adds links to NB_FileLinks.

# sample code for templates, based off the default stylesheet
#
# $NB_FileLinks
#
# CSS class: filelinks

# set BASE_URL for links to $FILELINK_DIR
#set_baseurl "./"

# space seperated list of sub-directories inside $BLOG_DIR, where files are located
set_filelinksconf(){
# e.g. FILELINKS_DIR="files stories poems long\ name\ with\ spaces"
: ${FILELINKS_DIR:=downloads}
: ${FILELINKS_SUFFIX:=*}
: ${FILELINKS_TEMPLATE:=$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE}
: ${FILELINKS_FILTERCMD:=sort}
: ${FILELINKS_TITLE_FILE=:.filelinks_title.txt}
}

# reset basic configs to allow for multiple filelinks.configs
reset_filelinksconf(){
FILELINKS_SUFFIX=; FILELINKS_TEMPLATE=
set_filelinksconf
}

FILELINK_PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/fileindex_links.$NB_FILETYPE"

add_filelinksindex(){
NB_FileLinksIndexTitle=
# Reads alternate title for list from $FILELINKS_TITLE_FILE (1st line).
[ -f "$BLOG_DIR/$FILELINK_DIR/$FILELINKS_TITLE_FILE" ] &&
	NB_FileLinksIndexTitle=`sed 1q $BLOG_DIR/$FILELINK_DIR/$FILELINKS_TITLE_FILE`
[ -z "$NB_FileLinksIndexTitle" ] && NB_FileLinksIndexTitle="$FILELINK_DIR"
cat >> "$FILELINK_PLUGIN_OUTFILE" <<-EOF
	<a href="${BASE_IRL}$FILELINK_DIR/$NB_INDEX">$NB_FileLinksIndexTitle</a><br />
EOF
NB_FileLinksIndexTitleHTML=$(< "$FILELINK_PLUGIN_OUTFILE")
> "$FILELINK_PLUGIN_OUTFILE"
}

add_filelink(){
echo '<!--'$FILELINK_TITLE'--><li><a href="'${BASE_URL}$FILELINK_DIR/$filelink'">'$FILELINK_TITLE'</a></li>' >> "$SCRATCH_FILE.filelinks"
}

create_filelinksindex(){
MKPAGE_TITLE="$FILELINK_DIR"
BLOGPAGE_SRCFILE="$SCRATCH_FILE.filelinks"
BLOGPAGE_OUTFILE="$BLOG_DIR/$FILELINK_DIR/index.$NB_FILETYPE"
weblog_page "$BLOGPAGE_SRCFILE" "$FILELINKS_TEMPLATE" "$BLOGPAGE_OUTFILE"
}

cycle_filelinks_for(){
build_part="$1"
cd "$BLOG_DIR/$FILELINK_DIR"
# small example for including hidden files
# for filelink_srcfile in .$FILELINKS_SUFFIX *.$FILELINKS_SUFFIX; do
for filelink_srcfile in *.$FILELINKS_SUFFIX; do
	if [ -f "$BLOG_DIR/$FILELINK_DIR/$filelink_srcfile" ] && [ "$filelink_srcfile" != "$NB_INDEX" ]; then
		FILELINK_TITLE="$filelink_srcfile"
		filelink="$filelink_srcfile"
		"$build_part"
	fi
done
}

> "$SCRATCH_FILE.filelinks"
> "$FILELINK_PLUGIN_OUTFILE"
set_filelinksconf
for filelinks_pass in 1 2; do
	for FILELINK_DIR in ${FILELINKS_DIR[@]}; do
		if [ -d "$BLOG_DIR/$FILELINK_DIR" ]; then
			# load filelinks config file
			FILELINK_CONF="$BLOG_DIR/$FILELINK_DIR/filelinks.conf"
			if [ -f "$FILELINK_CONF" ]; then
				reset_filelinksconf
				. "$FILELINK_CONF"
			fi
			if [ "$filelinks_pass" -lt 2 ]; then
				set_baseurl "./"
				add_filelinksindex
				cat > "$FILELINK_PLUGIN_OUTFILE" <<-EOF
					$NB_FileLinksIndexTitleHTML
				EOF
				NB_FileLinks=$(< "$FILELINK_PLUGIN_OUTFILE")
			else
				> "$SCRATCH_FILE.filelinks"
				nb_msg "$plugins_action file links for $BLOG_DIR/$FILELINK_DIR ..."
				set_baseurl "../"
				cycle_filelinks_for add_filelink
				NB_FileLinksHTML=`$FILELINKS_FILTERCMD "$SCRATCH_FILE.filelinks"`
				cat > "$SCRATCH_FILE.filelinks" <<-EOF
					<div class="filelinks">
						<ul>
							$NB_FileLinksHTML
						</ul>
					</div>
				EOF
				MKPAGE_CONTENT=$(< "$SCRATCH_FILE.filelinks")
				create_filelinksindex
			fi
		fi
	done
done
# clear settings
reset_filelinksconf
