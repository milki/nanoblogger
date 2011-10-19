# NanoBlogger Atom Feed Plugin
# synopsis: nb query feed [tag N] update

# concatenate modification variables
FEEDMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Cat_EntryFile$USR_TITLE"

# set URL for syndication feed
[ ! -z "$BLOG_URL" ] &&
	: ${BLOG_FEED_URL:=$BLOG_URL}

# use entry excerpts from entry excerpts plugin
# (excerpts plugin must be enabled to work)
: ${ENTRY_EXCERPTS:=0}

# set timezone used for feed
: ${BLOG_FEED_TZD:=$BLOG_TZD}
# limit number of items to include in feed
# backwards support for deprecated FEED_ITEMS
: ${BLOG_FEED_ITEMS:=$FEED_ITEMS}
: ${BLOG_FEED_ITEMS:=10}
: ${ATOM_ITEMS:=$BLOG_FEED_ITEMS}
# build atom feeds for categories (0/1 = off/on)
: ${ATOM_CATFEEDS:=0}

# Atom 1.0 CSS support
if [ -f "$BLOG_DIR/styles/feed.css" ] && [ -z "$BLOG_FEED_CSS" ]; then
	BLOG_FEED_CSS="styles/feed.css"
fi

# filename of atom feed
NB_AtomFile="atom.$NB_SYND_FILETYPE"
# atom feed version
NB_AtomVer="1.0"
# atom feed unique id (should be IRI as defined by RFC3987)
NB_AtomID="$BLOG_FEED_URL/"

NB_AtomModDate=`date "+%Y-%m-%dT%H:%M:%S${BLOG_FEED_TZD}"`

# set link to the archives
NB_AtomArchivesPath="$BLOG_FEED_URL/$ARCHIVES_DIR/"

# set link for main template
set_baseurl './'
NB_AtomFeedLink='<a href="'${BASE_URL}$NB_AtomFile'" class="feed-small">Atom</a>'

# set language of atom feed 
# unfortunately BLOG_FEED_LANG is useless here
: ${ATOM_FEED_LANG:=en}

# watch and reset chronological order
if [ "$CHRON_ORDER" != 1 ]; then
	RESTORE_SORTARGS="$SORT_ARGS"
	SORT_ARGS="-ru"
else
	RESTORE_SORTARGS=
fi

if [ ! -z "$FEEDMOD_VAR" ] || case "$NB_QUERY" in \
				all) ! [[ "$NB_UPDATE" == *arch ]];; \
				feed|feed[a-z]) :;; *) [ 1 = false ];; \
				esac; then

	# transform relative links for the entries
	set_baseurl "$BLOG_FEED_URL/"

	# escape special characters to help create valid xml feeds
	esc_chars(){
		sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
		}

	BLOG_FEED_TITLE=`echo "$BLOG_TITLE" |esc_chars`
	BLOG_FEED_SUBTITLE=`echo "$BLOG_DESCRIPTION" |esc_chars`
	NB_AtomAuthor=`echo "$BLOG_AUTHOR" |esc_chars`

	# make atom feed
	make_atomfeed(){
	MKPAGE_OUTFILE="$1"
	mkdir -p `dirname "$MKPAGE_OUTFILE"`
	BLOG_FEED_URLFILE="$BLOG_FEED_URL/$NB_AtomFile"
	NB_AtomTitle="$BLOG_FEED_TITLE"
	NB_AtomSubtitle="$BLOG_FEED_SUBTITLE"
	[ ! -z "$NB_AtomCatTitle" ] &&
		NB_AtomTitle="$template_catarchives $NB_AtomCatTitle | $BLOG_FEED_TITLE"
	[ ! -z "$NB_AtomCatLink" ] &&
		BLOG_FEED_URLFILE="$BLOG_FEED_URL/$ARCHIVES_DIR/$NB_AtomCatFile"

	# Atom 1.0 support for icons and logos
	if [ ! -z "$BLOG_FEED_ICON" ]; then
		NB_AtomIcon='<icon>'$BLOG_FEED_URL/$BLOG_FEED_ICON'</icon>'
	fi
	if [ ! -z "$BLOG_FEED_LOGO" ]; then
		NB_AtomLogo='<logo>'$BLOG_FEED_URL/$BLOG_FEED_LOGO'</logo>'
	fi

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
		<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="$ATOM_FEED_LANG">
		<?xml-stylesheet type="text/css" href="$BLOG_FEED_URL/$BLOG_FEED_CSS"?>
		$NB_AtomIcon
		$NB_AtomLogo
		<title type="html">$NB_AtomTitle</title>
		<subtitle type="html">$NB_AtomSubtitle</subtitle>
		<link rel="alternate" type="text/html" href="$BLOG_FEED_URL"/>
		<link rel="self" type="application/atom+xml" href="$BLOG_FEED_URLFILE"/>
		<updated>$NB_AtomModDate</updated>
		<author>
			<name>$NB_AtomAuthor</name>
			<uri>$BLOG_FEED_URL</uri>
		</author>
		<id>$NB_AtomID</id>
		<generator uri="http://nanoblogger.sourceforge.net" version="$VERSION">
			NanoBlogger
		</generator>

		$NB_AtomEntries

		</feed>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	# load makepage tidy plugin
	load_plugins makepage/tidy.sh
	NB_AtomTitle=
	}

	# generate feed entries
	build_atomfeed(){
	db_catquery="$1"
	query_db all "$db_catquery" limit "$ATOM_ITEMS"
	ARCHIVE_LIST=(${DB_RESULTS[@]})
	> "$SCRATCH_FILE".atomfeed
	for entry in ${ARCHIVE_LIST[@]}; do
		set_entrylink "$entry"
		load_entry "$NB_DATA_DIR/$entry" ALL
		Atom_EntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
		Atom_EntryDate=`echo "$Atom_EntryTime${BLOG_FEED_TZD}"`
		# non-portable find command!
		#Atom_EntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS${BLOG_FEED_TZD}"`
		Atom_EntryModDate="$Atom_EntryDate"
		Atom_EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		Atom_EntryAuthor=`echo "$NB_EntryAuthor" |esc_chars`
		[ -z "$Atom_EntryTitle" ] && Atom_EntryTitle="$notitle"
		# support for Atom 1.0 enclosures (requires 'du' system command for determing length)
		read_metadata ENCLOSURE "$NB_DATA_DIR/$entry"; NB_AtomTempEnclosure="$METADATA"
		Atom_EntryCategory=; cat_title=
		> "$SCRATCH_FILE".atomfeed-cat
		atomentry_wcatids=`grep "$entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
		atomentry_catids="${atomentry_wcatids##*\>}"
		[ "$atomentry_wcatids" = "$atomentry_catids" ] &&
			atomentry_catids=
		for atomentry_catdb in ${atomentry_catids//\,/ }; do
			cat_title=`nb_print "$NB_DATA_DIR"/cat_"$atomentry_catdb.$NB_DBTYPE" 1`
			cat_title=`echo "${cat_title##\,}" |esc_chars`
			if [ ! -z "$cat_title" ]; then
				cat >> "$SCRATCH_FILE".atomfeed-cat <<-EOF
					<category term="$cat_title" />
				EOF
			fi
		done
		Atom_EntryCategory=$(< "$SCRATCH_FILE".atomfeed-cat)
		if [ "$ENTRY_EXCERPTS" = 1 ] && [ ! -z "$NB_EntryExcerpt" ]; then
			#Atom_EntryExcerpt=`echo "$NB_EntryExcerpt" |esc_chars`
			Atom_EntryExcerpt="$NB_EntryExcerpt"
		else
			#Atom_EntryExcerpt=`echo "$NB_MetaBody" |esc_chars`
			Atom_EntryExcerpt="$NB_MetaBody"
		fi
		Atom_EntryEnclosure=; # initialize variable
		# dissect ENCLOSURE metadata
		if [ ! -z "$NB_AtomTempEnclosure" ]; then
			Enclosure_File=`echo "$NB_AtomTempEnclosure" |cut -d' ' -f 1`
			Enclosure_Type=`echo "$NB_AtomTempEnclosure" |cut -d' ' -f 2`
			[ -z "$Enclosure_Type" ] || [ "$Enclosure_Type" = "$Enclosure_File" ] &&
				Enclosure_Type="audio/mpeg"
			if [ -f "$BLOG_DIR/$Enclosure_File" ]; then
				Enclosure_Length=`du -b "$BLOG_DIR/$Enclosure_File" |sed -e '/[[:space:]].*$/ s///g'`
				Atom_EntryEnclosure='<link rel="enclosure" type="'$Enclosure_Type'" length="'$Enclosure_Length'" href="'$BLOG_FEED_URL/$Enclosure_File'" />'
			fi
		fi
		cat >> "$SCRATCH_FILE".atomfeed <<-EOF
			<entry>
				<title type="html">$Atom_EntryTitle</title>
				<author>
					<name>$Atom_EntryAuthor</name>
				</author>
				<link rel="alternate" type="text/html" href="${NB_AtomArchivesPath}$NB_EntryPermalink"/>
				$Atom_EntryEnclosure
				<id>${NB_AtomArchivesPath}$NB_EntryPermalink</id>
				<published>$Atom_EntryDate</published>
				<updated>$Atom_EntryModDate</updated>
				$Atom_EntryCategory
				<content type="xhtml">
					<div xmlns="http://www.w3.org/1999/xhtml">
						$Atom_EntryExcerpt
					</div>
				</content>

			</entry>
		EOF
	done
	NB_AtomEntries=$(< "$SCRATCH_FILE".atomfeed)
	}

	# generate cat feed entries
	build_atom_catfeeds(){
	db_categories=(${CAT_LIST[@]})
	if [ ! -z "${db_categories[*]}" ]; then
		for cat_db in ${db_categories[@]}; do
			if [ -f "$NB_DATA_DIR/$cat_db" ]; then
				set_catlink "$cat_db"
				NB_AtomCatTitle=`nb_print "$NB_DATA_DIR/$cat_db" 1 |esc_chars`
				NB_AtomCatFile=`echo "$category_file" |sed -e 's/[\.]'$NB_FILETYPE'/-atom.'$NB_SYND_FILETYPE'/g'`
				NB_AtomCatLink="$category_link"
				nb_msg "$plugins_action $category_dir atom $NB_AtomVer feed ..."
				build_atomfeed "$cat_db"
				make_atomfeed "$BLOG_DIR/$ARCHIVES_DIR/$NB_AtomCatFile"
			fi
		done
	fi
	}

	nb_msg "$plugins_action atom $NB_AtomVer feed ..."
	build_atomfeed nocat
	make_atomfeed "$BLOG_DIR/$NB_AtomFile"
	if [ "$CATEGORY_FEEDS" = 1 ] && [ "$ATOM_CATFEEDS" = 1 ]; then
		build_atom_catfeeds
	fi
fi

# restore chronological order
[ ! -z "$RESTORE_SORTARGS" ] &&
	SORT_ARGS="$RESTORE_SORTARGS"

