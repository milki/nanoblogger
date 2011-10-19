# Module for utility functions
# Last modified: 2010-02-14T15:15:35-05:00

# simple command evaluator that attempts to mask output
nb_eval(){
	DEVNULL=`eval "$1" 2>&1`
	return $?
}

# create a semi ISO 8601 formatted timestamp for archives
# used explicitly, please don't edit unless you know what you're doing.
nb_timestamp(){ $DATE_CMD $DB_DATEARGS +"$DB_DATEFORMAT"; }

# convert to a more printable date format
filter_timestamp(){
#echo "$1" |sed -e '/[\_]/ s//:/g; /[A-Z]/ s// /g'
entry_date=${1%%.$NB_DATATYPE}; entry_date=${entry_date//\_/:}
echo ${entry_date//[A-Z]/ }
}

# reverse filter time stamp to original form
refilter_timestamp(){
#echo "$1" |sed -e '/[\:]/ s//_/g; /[ ]/ s//T/'
entry_date=${1//\:/_}
echo ${entry_date//[ ]/T}
}

# validate time stamp
validate_timestamp(){
echo "$1" |grep '^[0-9][0-9][0-9][0-9][\-][0-9][0-9][\-][0-9][0-9][A-Z][0-9][0-9][\_][0-9][0-9][\_][0-9][0-9]$'
}

# filter custom date format for a new entry
# synopsis: filter_dateformat [date] [date args]
filter_dateformat(){
FILTER_DATE="$1"
FILTER_ARGS="$2"
: ${FILTER_ARGS:=$DATE_ARGS}
# use date's defaults, when no date format is specified
if [ ! -z "$FILTER_DATE" ]; then
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" $DATE_CMD $FILTER_ARGS +"$FILTER_DATE"
	[ -z "$DATE_LOCALE" ] && $DATE_CMD $FILTER_ARGS +"$FILTER_DATE"
else
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" $DATE_CMD $FILTER_ARGS
	[ -z "$DATE_LOCALE" ] && $DATE_CMD $FILTER_ARGS
fi
}

# filter custom date string using GNU specific 'date -d'
# synopsis: filter_datestring [date] [date args] [date description]
filter_datestring(){
FILTER_DATE="$1"
FILTER_ARGS="$2"
FILTER_DESC="$3"
: ${FILTER_ARGS:=$DATE_ARGS}
if [ ! -z "$DATE_FORMAT" ]; then
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_DESC"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_DESC"
else
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD $DATE_ARGS -d "$FILTER_DESC"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD $DATE_ARGS -d "$FILTER_DESC"
fi
}

# change suffix of file
chg_suffix(){
filename="$1"
suffix="$2"
old_suffix="${filename##*.}"
[ ! -z "$suffix" ] && NB_FILETYPE="$suffix"
echo "${filename//[\.]$old_suffix/.$NB_FILETYPE}"
}

# tool to require confirmation
confirm_action(){
echo "$confirmaction_ask [y/N]"
read -p "$NB_PROMPT" confirm
case $confirm in
	[Yy]);;
	[Nn]|"") die;;
esac
}

# sensible-browser-like utility (parses $NB_BROWSER, $BROWSER, and %s)
# synopsis: nb_browser [url]
# NOTE: $BROWSE_URL must be full path or some browsers complain
nb_browser(){
BROWSER_CMD="$NB_BROWSER"
BROWSER_URL="$1"
if [ ! -z "$BROWSER_CMD" ]; then
	BROWSER_LIST=`echo "$BROWSER_CMD" |sed -e '/[ ]/ s//%REM%/g; /\:/ s// /g'`
	for browser in $BROWSER_LIST; do
		browserurl_sedvar="${BROWSER_URL//\//\\/}"
		browser_cmd=`echo "$browser" |sed -e 's/\%REM\%/ /g; s/\%\%/\%/g; s/\%s/'$browserurl_sedvar'/g'`
		nb_msg "$nbbrowser_running $browser_cmd $BROWSER_URL ..."
		eval $browser_cmd "$BROWSER_URL" && break
		# on failure, continue to next in list
	done
	if [ $? != 0 ]; then
		nb_msg "$nbbrowser_nobrowser"
	fi
fi
}

# wrapper to editor command
# synopsis: nb_edit [options] file
nb_edit(){
EDIT_OPTIONS="$1"
EDIT_FILE="$2"
[ -z "$EDIT_FILE" ] && EDIT_FILE="$1"
# set directory being written to
EDIT_DIR="${EDIT_FILE%%\/${EDIT_FILE##*\/}}"
# assume current directory when no directory is found
[ ! -d "$EDIT_DIR" ] && EDIT_DIR="./"
# test directory for write permissions
[ ! -w "$EDIT_DIR" ] && [ -d "$EDIT_DIR" ] &&
	die "'$EDIT_DIR' - $nowritedir"
case "$EDIT_OPTIONS" in
	-p) # prompt to continue (kludge for editors that detach from process)
		eval $NB_EDITOR "$EDIT_FILE"
		read -p "$nbedit_prompt" enter_key
	;;
	*) # default action
		eval $NB_EDITOR "$EDIT_FILE"
	;;
esac
if [ ! -f "$EDIT_FILE" ]; then
	nb_msg "'$EDIT_FILE' - $nbedit_nofile"
	die "'$EDIT_FILE' - $nbedit_failed"
fi
}

# print a file (line by line)
# synopsis: nb_print file [number of lines|blank for all]
nb_print(){
nbprint_file="$1"
maxnbprint_cnt=$2
nbprint_cnt=0
while read line; do
	let nbprint_cnt=${nbprint_cnt}+1
	[ ! -z $maxnbprint_cnt ] && [ $nbprint_cnt -gt $maxnbprint_cnt ] &&
		break
	echo $line
done < $nbprint_file
}

# convert category number to existing cateogory database
cat_id(){
cat_query=(`echo "$1" |grep '[0-9]' |sed -e '/,/ s// /g; /[A-Z,a-z\)\.-]/d'`)
query_db
if [ ! -z "${cat_query[*]}" ]; then
	for cat_id in ${cat_query[@]}; do
		cat_valid=`for cat_db in ${db_categories[@]}; do echo $cat_db; done |grep cat_$cat_id.$NB_DBTYPE`
		echo "$cat_valid"
		[ -z "$cat_valid" ] &&
			nb_msg "$catid_bad"
	done
fi
}

# validate category's id number
check_catid(){
cat_list=(`cat_id "$1"`)
for cat_db in ${cat_list[@]}; do
	[ ! -f "$NB_DATA_DIR/$cat_db" ] &&
		die "$checkcatid_invalid $1"
done
[ ! -z "$1" ] && [ -z "${cat_list[*]}" ] && die "$checkcatid_novalid"
}

# check file for required metadata vars
check_metavars(){
VALIDATE_VARS="$1"
VALIDATE_METAFILE="$2"
for mvar in $VALIDATE_VARS; do
	MVAR_NUM=`grep -c "^$mvar" "$VALIDATE_METAFILE"`
	[ "$MVAR_NUM" = 0 ] &&
		die "'$VALIDATE_METAFILE' - $checkmetavars_novar '$mvar'"
done
}

# import metafile
import_file(){
IMPORT_FILE="$1"
if [ -f "$IMPORT_FILE" ]; then
	# validate metafile
	check_metavars "TITLE: AUTHOR: DATE: BODY: $METADATA_CLOSEVAR" \
		"$IMPORT_FILE"
	load_metadata ALL "$IMPORT_FILE"
	load_metadata HEADERS "$IMPORT_FILE"
else
	die "'$IMPORT_FILE' $importfile_nofile"
fi
}

# transliterate text into a suitable form for web links
translit_text(){ translittext_var="$1"; ttchar_limit=${MAX_TITLEWIDTH}
nonascii="${translittext_var//[a-zA-Z0-9_-]/}" # isolate all non-printable/non-ascii characters
echo "${translittext_var:0:$ttchar_limit}" |sed -e "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/; s/[\`\~\!\@\#\$\%\^\*\(\)\+\=\{\}\|\\\;\:\'\"\,\<\>\/\?]//g; s/ [\&] / and /g; s/^[ ]//g; s/[ ]$//g; s/[\.]/_/g; s/\[//g; s/\]//g; s/ /_/g; s/[$nonascii ]/_/g" |sed -e '/[\_\-]*$/ s///g; /[\_\-]$/ s///g'
}

# tool to lookup ID from master database
lookup_id(){
INPUT_IDLIST=($2)
for db_item in ${INPUT_IDLIST[@]}; do
	echo $db_item
done |grep -n "$1" |cut -d":" -f 1 |grep '^[0-9].*$'
}

# tool to find entry before and after from entry's id
findba_entries(){
BAENTRY_IDLIST=($2)
entryid_var=`lookup_id "$1" "${BAENTRY_IDLIST[*]}"`
# adjust offset by 1 for bash arrays (1 = 0)
((entryid_var--))
# determine direction based on chronological date order
if [ "$CHRON_ORDER" = 1 ]; then
	let before_entryid=${entryid_var}+1
	let after_entryid=${entryid_var}-1
else
	let before_entryid=${entryid_var}-1
	let after_entryid=${entryid_var}+1
fi
if [ "$before_entryid" -ge 0 ]; then
	before_entry=${BAENTRY_IDLIST[$before_entryid]%%\>[0-9]*}
else
	before_entry=
fi
if [ "$after_entryid" -ge 0 ]; then
	after_entry=${BAENTRY_IDLIST[$after_entryid]%%\>[0-9]*}
else
	after_entry=
fi
}

# tool to build list of related categories from list of entries
find_categories(){
FIND_CATLIST=($1)
cat_list=()
build_catlist(){
[ ! -z "$cat_var" ] &&
	cat_list=( ${cat_list[@]} $cat_db )
}
# acquire all the categories
for relative_entry in ${FIND_CATLIST[@]}; do
	raw_db "$relative_entry"
	cat_ids=`print_cat "${DB_RESULTS[*]}"`
	cat_ids="${cat_ids//\,/ }"
	for cat_id in $cat_ids; do
		cat_var="$cat_id"
		cat_db="cat_$cat_id.$NB_DBTYPE"
		build_catlist
	done
	cat_id=; cat_ids=; cat_var=; cat_db=;
done
CAT_LIST=( ${cat_list[@]} )
[ -z "${CAT_LIST[*]}" ] && [ ! -z "$cat_num" ] &&
	CAT_LIST=( `cat_id "$cat_num"` )
[ "$UPDATE_WEBLOG" = 1 ] && [ "$NB_QUERY" = all ] && [ -z "$cat_num" ] && 
	CAT_LIST=${db_categories[@]}
CAT_LIST=(`for cat_id in ${CAT_LIST[@]}; do echo "$cat_id"; done |sort -u`)
}

# resort category databases from list
resort_categories(){
RESORT_CATDBLIST=($1)
[ -z "${RESORT_CATDBLIST[*]}" ] && RESORT_CATDBLIST=(${CAT_LIST[*]})
for mod_catdb in ${CAT_LIST[@]}; do
	resort_catdb "$NB_DATA_DIR/$mod_catdb"
done
}

# update categories with cateogory id's from main db with list of entries
update_categories(){
UPDATE_CATLIST=($1)
[ -z "${UPDATE_CATLIST[*]}" ] && UPDATE_CATLIST=(${UPDATE_LIST[*]})
for ucat_entry in ${UPDATE_CATLIST[@]}; do
	cat_ids=`get_catids "$ucat_entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
	cat_ids="${cat_ids//\,/ }"
	for cat_id in $cat_ids; do
		cat_var="$cat_id"
		cat_db="cat_$cat_id.$NB_DBTYPE"
		update_catdb "$ucat_entry" "$NB_DATA_DIR/$cat_db"
	done
	cat_id=; cat_ids=; cat_var=; cat_db=;
done
}

# generate timestamp as metadata variables
meta_timestamp(){
NB_MetaDate=`filter_dateformat "$DATE_FORMAT"`
NB_MetaTimeStamp=`nb_timestamp`
# fallback to printable timestamp
if [ -z "$NB_MetaDate" ]; then
	nb_msg "$filter_datefailed"
	NB_MetaDate=`filter_timestamp "$NB_MetaTimeStamp"`
fi
}

# read file's metadata
read_metadata(){
META_FILE="$2"
MVAR_CLOSE=`echo "$1" |sed -e '/[^ ].*[\,]/ s///'`
if [ "$1" != "$MVAR_CLOSE" ] && [ ! -z "$MVAR_CLOSE" ]; then
	MVAR=`echo "$1" |sed -e '/[\,].*[^ ]$/ s///'`
	METADATA=`sed -e '/^'$MVAR'[\:]/,/^'$MVAR_CLOSE'/!d; /^'$MVAR'[\:]/d; /^'$MVAR_CLOSE'/d' "$META_FILE"`
else
	METADATA=`sed -e '/^'$1'[\:]/!d; /^'$1'[\:] */ s///' "$META_FILE"`
fi
}

# load metadata from file into tangible shell variables
load_metadata(){
METADATA_TYPE="$1" # ALL, NOBODY, or valid metadata key
METADATA_FILE="$2"
[ ! -f "$METADATA_FILE" ] &&
	die "'$METADATA_FILE' $importfile_nofile"
case $METADATA_TYPE in
	AUTHOR)
		read_metadata AUTHOR "$METADATA_FILE"; NB_MetaAuthor="$METADATA"
		NB_EntryAuthor="$NB_MetaAuthor";;
	BODY|CONTENT)
		read_metadata "BODY,$METADATA_CLOSEVAR" "$METADATA_FILE"; NB_MetaBody="$METADATA"
		NB_EntryBody="$NB_MetaBody";;
	DATE)
		read_metadata DATE "$METADATA_FILE"; NB_MetaDate="$METADATA"
		NB_EntryDate="$NB_MetaDate";;
	DESC)
		NB_EntryDescription="$NB_MetaDescription"
		read_metadata FORMAT "$METADATA_FILE"; NB_MetaFormat="$METADATA";;
	FORMAT)
		read_metadata FORMAT "$METADATA_FILE"; NB_MetaFormat="$METADATA"
		NB_EntryFormat="$NB_MetaFormat";;
	HEADERS)
		: ${METADATA_MARKER:=-----}
		: ${METADATA_CLOSEVAR:=END-----}
		METADATA_HEADERS=`sed -e '1,/^'$METADATA_MARKER'/!d; /^'$METADATA_MARKER'/d' "$METADATA_FILE"`
		METADATA_CONTENT=`sed -e '/^'$METADATA_MARKER'/,/^'$METADATA_CLOSEVAR'/!d' "$METADATA_FILE"`;;
	TITLE)
		read_metadata TITLE "$METADATA_FILE"; NB_MetaTitle="$METADATA"
		NB_EntryTitle="$NB_MetaTitle";;
	ALL)
		for LMDATATYPE in AUTHOR TITLE DATE DESC FORMAT BODY; do
			load_metadata $LMDATATYPE "$METADATA_FILE"
		done;;
	NOBODY)
		for LMDATATYPE in AUTHOR TITLE DATE DESC FORMAT; do
			load_metadata $LMDATATYPE "$METADATA_FILE"
		done;;
	*)
		load_metadata ALL "$METADATA_FILE";;
esac
}

# write metadata out to file
write_metadata(){
WRITE_MDATA="$2"
META_FILE="$3"
MVAR_CLOSE=`echo "$1" |sed -e '/[^ ].*[\,]/ s///'`
if [ ! -z "$1" ] && [ ! -z "$WRITE_MDATA" ]; then
	if [ "$1" != "$MVAR_CLOSE" ] && [ ! -z "$MVAR_CLOSE" ]; then
		MVAR=`echo "$1" |sed -e '/[\,].*[^ ]$/ s///'`
		if [ -f "$META_FILE" ]; then
			META_OTHER=`sed -e '/^'$MVAR'[\:]/,/^'$MVAR_CLOSE'/d; /^'$MVAR'[\:]/d; /^'$MVAR_CLOSE'/d' "$META_FILE"`
		fi
		cat > "$META_FILE" <<-EOF
			$META_OTHER
			$MVAR:
			$WRITE_MDATA
			$MVAR_CLOSE
		EOF
	elif [ -f "$META_FILE" ]; then
		METAVAR_MATCH=`grep "^$1[\:]" "$META_FILE"`
		# first, try replacing meta-tag, while preserving structure
		if [ ! -z "$METAVAR_MATCH" ]; then
			load_metadata HEADERS "$META_FILE"
			SAVED_METADATACONTENT="$METADATA_CONTENT"
			if [ ! -z "$METADATA_HEADERS" ]; then
				# prevent command line substutition and shell variable expansion in titles
				read_metadata TITLE "$META_FILE"; NB_MetaTitle="$METADATA"
				if [ ! -z "$METADATA" ]; then
					sed -e '/^TITLE[\:].*/ s//TITLE: \$NB_MetaTitle/g' > "$META_FILE" <<-EOF
						$METADATA_HEADERS
					EOF
				fi
				load_metadata HEADERS "$META_FILE"
				sed -e '/^'$1'[\:].*/ s//'$1': \$NB_MetaOther/g' > "$META_FILE" <<-EOF
					$METADATA_HEADERS
				EOF
				NB_MetaOther="$WRITE_MDATA"
				# expands all variables in METADATA_HEADERS
				load_template "$META_FILE"
				write_template > "$META_FILE"
				echo "$SAVED_METADATACONTENT" >> "$META_FILE"
			fi
		else
			# second, try stacking new/modified meta-tag on top, disregarding structure,
			# while preserving data
			META_OTHER=`sed -e '/^'$1'[\:]/d' "$META_FILE"`
			cat > "$META_FILE" <<-EOF
				$1: $WRITE_MDATA
				$META_OTHER
			EOF
		fi
	fi
fi
}

# create/modify user metadata field
write_var(){
WRITE_MVAR="$1"
WRITE_MVARVALUE="$2"
WRITEMETAVAR_FILE="$3"
[ ! -z "$USR_METAVAR" ] && WRITE_MVAR="$USR_METAVAR"
[ ! -z "$USR_SETVAR" ] && WRITE_MVARVALUE="$USR_SETVAR"
if [ ! -z "$WRITE_MVAR" ]; then
	write_metadata "$WRITE_MVAR" "$WRITE_MVARVALUE" \
		"$WRITEMETAVAR_FILE"
fi
}

# write entry's metadata to file
write_entry(){
WRITE_ENTRY_FILE="$1"
# help ease transition from 3.2.x or earlier
[ ! -f "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAENTRY_TEMPLATE" "$NB_TEMPLATE_DIR"
NB_EntryBody="$NB_MetaBody" # set here for entry template
load_template "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE"
mkdir -p `dirname "$WRITE_ENTRY_FILE"`
write_template > "$WRITE_ENTRY_FILE"
write_var "$USR_METAVAR" "$USR_SETVAR" "$WRITE_ENTRY_FILE"
}

# load entry from it's metadata file
load_entry(){
ENTRY_FILE="$1"
ENTRY_DATATYPE="$2"
ENTRY_CACHETYPE="$3"
: ${ENTRY_PLUGINSLOOP:=shortcode entry/mod entry/format entry}
: ${ENTRY_DATATYPE:=ALL}
if [ -f "$ENTRY_FILE" ]; then
	entry_day=${entry:8:2}
	entry_time=`filter_timestamp "$entry"`
	entry_time=${entry_time:11:8}
	if [ -z "$ENTRY_CACHETYPE" ]; then
		if [ ! -z "$CACHE_TYPE" ]; then
			ENTRY_CACHETYPE="$CACHE_TYPE"
		else
			ENTRY_CACHETYPE=metadata
		fi
	fi
	if [ "$ENTRY_DATATYPE" != ALL ] || [ "$ENTRY_DATATYPE" = NOBODY ]; then
		NB_EntryID=$x_id${entry//[\/]/-}
		load_metadata "$ENTRY_DATATYPE" "$ENTRY_FILE"
		load_plugins entry
	else
		NB_EntryID=$x_id${entry//[\/]/-}
		# use cache when entry data unchanged
		if [ "$ENTRY_FILE" -nt "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE" ]; then
			#nb_msg "UPDATING CACHE - $entry.$ENTRY_CACHETYPE"
			load_metadata ALL "$ENTRY_FILE"
			for entry_pluginsdir in $ENTRY_PLUGINSLOOP; do
				if [ "$entry_pluginsdir" = "entry/format" ]; then
					[ -z "$NB_EntryFormat" ] && NB_EntryFormat="$ENTRY_FORMAT"
					load_plugins $entry_pluginsdir "$NB_EntryFormat"
				else
					load_plugins $entry_pluginsdir
				fi
			done
			write_entry "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE"
			# update cache list for some post-cache management
			#update_cache build $ENTRY_CACHETYPE "$entry"
		else
			#nb_msg "LOADING CACHE - $entry.$ENTRY_CACHETYPE"
			load_metadata ALL "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE"
			load_plugins entry
		fi
	fi
fi
}

# create file with metadata fields
make_file(){
WRITE_META_FILE="$1"
WRITE_META_TEMPLATE="$2"
# defaults to metafile template
[ -z "$WRITE_META_TEMPLATE" ] &&
	WRITE_META_TEMPLATE="$NB_TEMPLATE_DIR/$METADATAFILE_TEMPLATE"
# help ease transition from 3.2.x or earlier
[ ! -f "$NB_TEMPLATE_DIR/$METADATAFILE_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAFILE_TEMPLATE" "$NB_TEMPLATE_DIR"
# accept user metadata
[ ! -z "$USR_AUTHOR" ] && NB_MetaAuthor="$USR_AUTHOR"
[ -z "$NB_MetaAuthor" ] && NB_MetaAuthor="$BLOG_AUTHOR"
[ ! -z "$USR_DESC" ] && NB_MetaDescription="$USR_DESC"
if [ ! -z "$USR_TITLE" ]; then
	NB_MetaTitle="$USR_TITLE"; USR_TITLE=
fi
[ ! -z "$USR_TEXT" ] && NB_MetaBody="$USR_TEXT"
meta_timestamp
load_template "$WRITE_META_TEMPLATE"
write_template > "$WRITE_META_FILE"
write_var "$USR_METAVAR" "$USR_SETVAR" "$WRITE_META_FILE"
}

# create weblog page from text (parts) files
make_page(){
MKPAGE_SRCFILE="$1"
MKPAGE_TEMPLATE="$2"
MKPAGE_OUTFILE="$3"
if [ -z "$MKPAGE_TITLE" ] && [ ! -z "$USR_TITLE" ]; then
	MKPAGE_TITLE="$USR_TITLE"; USR_TITLE=
fi
if [ ! -z "$MKPAGE_TITLE" ]; then
	NB_MetaTitle="$MKPAGE_TITLE"
	# Set NB_EntryTitle for backwards compatibility
	NB_EntryTitle="$MKPAGE_TITLE"
fi
[ ! -z "$USR_TEMPLATE" ] && MKPAGE_TEMPLATE="$USR_TEMPLATE"
[ -z "$MKPAGE_TEMPLATE" ] &&
	MKPAGE_TEMPLATE="$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE"
[ ! -f "$MKPAGE_SRCFILE" ] && die "'$MKPAGE_SRCFILE' - $makepage_nosource"
[ -z "$MKPAGE_OUTFILE" ] && die "'$MKPAGE_OUTFILE' - $makepage_nooutput"
[ ! -f "$MKPAGE_TEMPLATE" ] && die "'$MKPAGE_TEMPLATE' - $makepage_notemplate"
# make sure the output directory is present before writing to it
mkdir -p `dirname "$MKPAGE_OUTFILE"`
set_baseurl "" "$MKPAGE_OUTFILE"
# load file as content
: ${MKPAGE_CONTENT:=$(< "$MKPAGE_SRCFILE")}
# let plugins modify the content
load_plugins page
: ${MKPAGE_FORMAT:=$PAGE_FORMAT}
load_plugins page/format "$MKPAGE_FORMAT"
NB_MetaBody="$MKPAGE_CONTENT"; NB_Entries="$MKPAGE_CONTENT" # leave here for backwards compatibility
load_template "$MKPAGE_TEMPLATE"
mkdir -p `dirname "$MKPAGE_OUTFILE"`
write_template > "$MKPAGE_OUTFILE"
nb_msg "$MKPAGE_OUTFILE"
load_plugins makepage
MKPAGE_CONTENT=; MKPAGE_FORMAT=; MKPAGE_TITLE=; NB_MetaTitle=; NB_EntryTitle=
}

# creates weblog page from metafile
weblog_page(){
BLOGPAGE_SRCFILE="$1"
BLOGPAGE_TEMPLATE="$2"
BLOGPAGE_OUTFILE="$3"
[ ! -z "$USR_TEMPLATE" ] && BLOGPAGE_TEMPLATE="$USR_TEMPLATE"
if [ -f "$BLOGPAGE_SRCFILE" ]; then
	write_var "$USR_METAVAR" "$USR_SETVAR" "$BLOGPAGE_SRCFILE"
	load_metadata ALL "$BLOGPAGE_SRCFILE"
	[ ! -z "$USR_AUTHOR" ] && NB_MetaAuthor="$USR_AUTHOR"
	[ -z "$NB_MetaAuthor" ] && NB_MetaAuthor="$BLOG_AUTHOR"
	[ ! -z "$USR_DESC" ] && NB_MetaDescription="$USR_DESC"
	[ ! -z "$USR_TITLE" ] && NB_MetaTitle="$USR_TITLE"
	[ ! -z "$USR_TEXT" ] && NB_MetaBody="$USR_TEXT"
	for weblogpage_plugin in shortcode page/mod; do
		load_plugins $weblogpage_plugin
	done
	MKPAGE_CONTENT="$NB_MetaBody"
	MKPAGE_FORMAT="$NB_MetaFormat"
	: ${MKPAGE_FORMAT:=$BLOGPAGE_FORMAT}
	make_page "$BLOGPAGE_SRCFILE" "$BLOGPAGE_TEMPLATE" "$BLOGPAGE_OUTFILE"
fi
}

# edit draft file
nb_draft(){
EDITDRAFT_OPTIONS="$1"
EDITDRAFT_FILE="$2"
[ -z "$EDITDRAFT_FILE" ] && EDITDRAFT_FILE="$1"
[ ! -z "$USR_DRAFTFILE" ] && EDITDRAFT_FILE="$USR_DRAFTFILE"
if [ ! -z "$EDITDRAFT_FILE" ] && [ ! -f "$EDITDRAFT_FILE" ]; then
	echo "'$EDITDRAFT_FILE' - $nbdraft_asknew [Y/n]"
	read -p "$NB_PROMPT" choice
	case $choice in
		[Yy]|"")
			make_file "$EDITDRAFT_FILE" "$USR_TEMPLATE";;
		[Nn])
		;;
	esac
fi
if [ -f "$EDITDRAFT_FILE" ]; then
	write_var "$USR_METAVAR" "$USR_SETVAR" "$EDITDRAFT_FILE"
	nb_edit "$EDITDRAFT_OPTIONS" "$EDITDRAFT_FILE"
	# validate metafile
	check_metavars "TITLE: BODY: $METADATA_CLOSEVAR" "$EDITDRAFT_FILE"
	# modify date (DATE metadata)
	meta_timestamp && write_metadata DATE "$NB_MetaDate" "$EDITDRAFT_FILE"
fi
}

preview_weblog(){
if [ "$NOPREVIEW_WEBLOG" != 1 ] || [ "$PREVIEW_WEBLOG" = 1 ]; then
	[ -z "$BLOG_PREVIEW_CMD" ] && die "$preview_nocmd"
	if [ "$BLOG_INTERACTIVE" = 1 ]; then
		echo "$preview_asknow [y/N]"
		read -p "$NB_PROMPT" choice
		case $choice in
			[Yy])
				nb_msg "$preview_action"
				$BLOG_PREVIEW_CMD;;
			[Nn]|"")
			;;
		esac
	else
		nb_msg "$preview_action"
		$BLOG_PREVIEW_CMD
	fi
fi
}

publish_weblog(){
if [ "$NOPUBLISH_WEBLOG" != 1 ] || [ "$PUBLISH_WEBLOG" = 1 ]; then
	[ -z "$BLOG_PUBLISH_CMD" ] && die "$publish_nocmd"
	if [ "$BLOG_INTERACTIVE" = 1 ]; then
		echo "$publish_asknow [y/N]"
		read -p "$NB_PROMPT" choice
		case $choice in
			[Yy])
				nb_msg "$publish_action"
				$BLOG_PUBLISH_CMD;;
			[Nn]|"")
				;;
		esac
	else
		nb_msg "$publish_action"
		$BLOG_PUBLISH_CMD
	fi
fi
}

# tool to help manage the cache
update_cache(){
cache_update="$1"
cache_def="$2"
CACHEUPDATE_LIST=($3)
# pre-processing for extensive update-cache options
if [ "$UPDATE_WEBLOG" = 1 ]; then
	updcache_type="$updweblog_type"
	updatec_idsel="$update_idsel"
fi
if [ "$QUERY_WEBLOG" != 1 ] && [ -z "$cache_update" ]; then
	cache_update="$updcache_type"
fi
[ -z "$cache_update" ] && cache_update=expired
[ ! -z "$cat_num" ] && cache_update=rebuild
case "$updcache_type" in
	tag|tag[a-z]) cache_update=rebuild; cat_num="$updatec_idsel"
		db_catquery=`cat_id "$cat_num"`; check_catid "$cat_num"
esac
case "$cache_update" in
	build)
	[ -z "$cache_def" ] && cache_def="*"
	if [ -z "${CACHEUPDATE_LIST[*]}" ]; then
		query_db "$db_query" "$db_catquery"
		CACHEUPDATE_LIST=(${DB_RESULTS[*]})
	fi
	for cache_item in ${CACHEUPDATE_LIST[@]}; do
		echo "$cache_item" >> "$SCRATCH_FILE".cache_list.tmp
	done
	CACHEUPDATE_LIST=($(< "$SCRATCH_FILE".cache_list.tmp));;
	rebuild)
	> "$SCRATCH_FILE".cache_list.tmp
	[ -z "$cache_def" ] && cache_def="*"
	if [ -z "${CACHEUPDATE_LIST[*]}" ]; then
		query_db "$db_query" "$db_catquery"
		CACHEUPDATE_LIST=(${DB_RESULTS[*]})
	fi
	for cache_item in ${CACHEUPDATE_LIST[@]}; do
		echo "$cache_item" >> "$SCRATCH_FILE".cache_list.tmp
		rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item".$cache_def
	done
	CACHEUPDATE_LIST=($(< "$SCRATCH_FILE".cache_list.tmp));;
	expired)
	[ -z "$cache_def" ] && cache_def="*"
	# always cache more recent entries
	[ "$CHRON_ORDER" != 1 ] && db_order="-ru"
	query_db all "$db_catquery" limit "$MAX_CACHE_ENTRIES" "" "$db_order"
	for cache_item in "$BLOG_DIR/$CACHE_DIR"/*.$cache_def; do
		cache_item=${cache_item##*\/}
		cache_regex="${cache_item%%\.$cache_def*}"
		cache_match=`echo "${DB_RESULTS[*]}" |grep -c "$cache_regex"`
		[ "$cache_match" = 0 ] &&
			rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item"
	done;;
	*)
	[ -z "$cache_def" ] && cache_def="*"
	[ ! -z "$cache_update" ] && query_db "$cache_update" "$db_catquery"
	for cache_item in ${DB_RESULTS[@]}; do
		rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item".$cache_def
	done;;
esac
[ ! -z "${CACHEUPDATE_LIST[*]}" ] &&
	CACHE_LIST=(`for cache_item in ${CACHEUPDATE_LIST[@]}; do echo $cache_item; done |sort -u`)
}

# tool to help change an entry's date/timestamp
# (e.g. TIMESTAMP: YYYY-MM-DD HH:MM:SS)
chg_entrydate(){
EntryDate_File="$1"
EntryDate_TimeStamp="$2"
# read timestamp from command line
[ "$USR_METAVAR" = TIMESTAMP ] &&
	EntryDate_TimeStamp="$USR_SETVAR"
# validate timestamp format
Edit_EntryTimeStamp=`refilter_timestamp "$EntryDate_TimeStamp"`
New_EntryTimeStamp=`validate_timestamp "$Edit_EntryTimeStamp"`
# abort if we don't have a valid timestamp
[ ! -z "$EntryDate_TimeStamp" ] && [ -z "$New_EntryTimeStamp" ] &&
	die "$novalid_entrytime"
if [ ! -z "$New_EntryTimeStamp" ]; then
	[ ! -f "$SCRATCH_FILE.mod-catdbs" ] &&
		> "$SCRATCH_FILE.mod-catdbs"
	New_EntryDateFile="$New_EntryTimeStamp.$NB_DATATYPE"
	# abort if a possible conflict arises
	[ -f "$NB_DATA_DIR/$New_EntryDateFile" ] && die "$invalid_entrytime"
	if [ -f "$NB_DATA_DIR/$EntryDate_File" ] && [ "$EntryDate_File" != "$New_EntryDateFile" ]; then
		Old_EntryFile="$EntryDate_File"
		mv "$NB_DATA_DIR/$Old_EntryFile" "$NB_DATA_DIR/$New_EntryDateFile"
		set_entrylink "$Old_EntryFile"
		Delete_PermalinkFile="$BLOG_DIR/$ARCHIVES_DIR/$permalink_file"
		Delete_PermalinkDir="$BLOG_DIR/$ARCHIVES_DIR/$entry_dir"
		# delete old permalink file
		[ -f "$Delete_PermalinkFile" ] && rm -fr "$Delete_PermalinkFile"
		# delete old permalink directory
		[ ! -z "$entry_dir" ] && [ -d "$Delete_PermalinkDir" ] &&
			rm -fr "$Delete_PermalinkDir"
		# delete the old cache data
		rm -f "$BLOG_DIR/$CACHE_DIR/$Old_EntryFile".*
	fi
	NEWDATE_STRING=`echo "$New_EntryTimeStamp" |sed -e 's/[A-Z,a-z]/ /g; s/[\_]/:/g'`
	NB_NewEntryDate=$(filter_datestring "$DATE_FORMAT" "" "$NEWDATE_STRING")
	if [ ! -z "$NB_NewEntryDate" ]; then
		write_metadata DATE "$NB_NewEntryDate" "$NB_DATA_DIR/$New_EntryDateFile"
	else
		# fallback to timestamp
		nb_msg "$filterdate_failed"
		NB_NewEntryDate="$EntryDate_TimeStamp"
		write_metadata DATE "$NB_NewEntryDate" "$NB_DATA_DIR/$New_EntryDateFile"
	fi
fi
}

