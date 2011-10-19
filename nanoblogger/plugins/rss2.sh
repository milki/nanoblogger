# NanoBlogger RSS 2.0 Feed Plugin
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
: ${RSS2_ITEMS:=$BLOG_FEED_ITEMS}
# build rss2 feeds for categories (0/1 = off/on)
: ${RSS2_CATFEEDS:=0}

# RSS 2.0 CSS support
if [ -f "$BLOG_DIR/styles/feed.css" ] && [ -z "$BLOG_FEED_CSS" ]; then
	BLOG_FEED_CSS="styles/feed.css"
fi

# output filename of rss feed
NB_RSS2File="rss.$NB_SYND_FILETYPE"
# rss version
NB_RSS2Ver="2.0"

NB_RSS2ModDate=`date "+%Y-%m-%dT%H:%M:%S${BLOG_FEED_TZD}"`

# set link to archives
NB_RSS2ArchivesPath="$BLOG_FEED_URL/$ARCHIVES_DIR/"

# set link for main template
set_baseurl './'
NB_RSS2FeedLink='<a href="'${BASE_URL}$NB_RSS2File'" class="feed-small">RSS</a>'

# backwards support for deprecated BLOG_LANG
: ${BLOG_FEED_LANG:=$BLOG_LANG}

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
	NB_RSS2Author=`echo "$BLOG_AUTHOR" |esc_chars`

	# make rss feed
	make_rssfeed(){
	MKPAGE_OUTFILE="$1"
	mkdir -p `dirname "$MKPAGE_OUTFILE"`
	BLOG_FEED_URLFILE="$BLOG_FEED_URL/$NB_RSS2File"
	NB_RSS2Title="$BLOG_FEED_TITLE"
	[ ! -z "$NB_RSS2CatTitle" ] &&
		NB_RSS2Title="$template_catarchives $NB_RSS2CatTitle | $BLOG_FEED_TITLE"
	if [ ! -z "$NB_RSS2CatLink" ]; then 
		NB_RSS2File="$ARCHIVES_DIR/$NB_RSS2CatFile"
		BLOG_FEED_URLFILE="$BLOG_FEED_URL/$NB_RSS2File"
	fi
	# RSS 2.0 support for icons/logos
	# use syndication logo for when no icon is set
	: ${BLOG_FEED_ICON:=$BLOG_FEED_LOGO}
	if [ ! -z "$BLOG_FEED_ICON" ]; then
		NB_RSS2Logo='<image><link>'$BLOG_FEED_URL'</link><url>'$BLOG_FEED_URL'/'$BLOG_FEED_ICON'</url><title>'$NB_RSS2Title'</title></image>'
	fi

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
        <?xml-stylesheet type="text/css" href="${BASE_URL}$BLOG_FEED_CSS"?>
		<rss version="2.0"
		 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		 xmlns:dc="http://purl.org/dc/elements/1.1/"
		 xmlns:admin="http://webns.net/mvcb/"
		 xmlns:atom="http://www.w3.org/2005/Atom"
		>
		<channel>
			<title>$NB_RSS2Title</title>
			<atom:link href="$BLOG_FEED_URLFILE" rel="self" type="application/rss+xml" />
			<link>$BLOG_FEED_URL</link>
			<description>$BLOG_DESCRIPTION</description>
			<dc:language>$BLOG_FEED_LANG</dc:language>
			<dc:creator>$NB_RSS2Author</dc:creator>
			<dc:date>$NB_RSS2ModDate</dc:date>
			<admin:generatorAgent rdf:resource="http://nanoblogger.sourceforge.net" />
			$NB_RSS2Logo
			$NB_RSS2Entries
		</channel>
		</rss>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	# load makepage tidy plugin
	load_plugins makepage/tidy.sh
	NB_RSS2Title=
	}

	# generate feed entries
	build_rssfeed(){
	db_catquery="$1"
	query_db all "$db_catquery" limit "$RSS2_ITEMS"
	ARCHIVE_LIST=(${DB_RESULTS[@]})
	> "$SCRATCH_FILE".rss2feed
	for entry in ${ARCHIVE_LIST[@]}; do
		NB_RSS2EntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
		set_entrylink "$entry"
		load_entry "$NB_DATA_DIR/$entry" ALL
		# non-portable find command! sets RFC822 date for pubDate
		#NB_RSS2EntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%Ta, %Td %Tb %TY %TH:%TM:%TS %Tz\n"`
		NB_RSS2EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		NB_RSS2EntryAuthor=`echo "$NB_EntryAuthor" |esc_chars`
		[ -z "$NB_RSS2EntryTitle" ] && NB_RSS2EntryTitle="$notitle"
		NB_RSS2EntrySubject=; cat_title=; oldcat_title=
		# support for RSS 2.0 enclosures (requires 'du' system command for determing length)
		read_metadata ENCLOSURE "$NB_DATA_DIR/$entry"; NB_RSS2TempEnclosure="$METADATA"
		rss2entry_wcatids=`grep "$entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
		rss2entry_catids="${rss2entry_wcatids##*\>}"
		[ "$rss2entry_wcatids" = "$rss2entry_catids" ] &&
			rss2entry_catids=
		for rss2_catnum in ${rss2entry_catids//\,/ }; do
			cat_title=`nb_print "$NB_DATA_DIR"/cat_"$rss2_catnum.$NB_DBTYPE" 1`
			[ "$cat_title" != "$oldcat_title" ] &&
				cat_title="$oldcat_title $cat_title"
			oldcat_title="$cat_title,"
		done
		if [ ! -z "$cat_title" ]; then
			cat_title=`echo "${cat_title##\,}" |esc_chars`
			NB_RSS2EntrySubject=`echo '<dc:subject>'$cat_title'</dc:subject>'`
		fi
		if [ "$ENTRY_EXCERPTS" = 1 ] && [ ! -z "$NB_EntryExcerpt" ]; then
			#NB_RSS2EntryExcerpt=`echo "$NB_EntryExcerpt" |esc_chars`
			NB_RSS2EntryExcerpt="$NB_EntryExcerpt"
		else
			#NB_RSS2EntryExcerpt=`echo "$NB_MetaBody" |esc_chars`
			NB_RSS2EntryExcerpt="$NB_MetaBody"
		fi
		# for escaped text/html only
		#<description><![CDATA[$NB_RSS2EntryExcerpt]]></description>
		NB_RSS2EntryEnclosure=; # initialize variable
		# dissect ENCLOSURE metadata
		if [ ! -z "$NB_RSS2TempEnclosure" ]; then
			Enclosure_File=`echo "$NB_RSS2TempEnclosure" |cut -d' ' -f 1`
			Enclosure_Type=`echo "$NB_RSS2TempEnclosure" |cut -d' ' -f 2`
			[ -z "$Enclosure_Type" ] || [ "$Enclosure_Type" = "$Enclosure_File" ] &&
				Enclosure_Type="audio/mpeg"
			if [ -f "$BLOG_DIR/$Enclosure_File" ]; then
				Enclosure_Length=`du -b "$BLOG_DIR/$Enclosure_File" |sed -e '/[[:space:]].*$/ s///g'`
				NB_RSS2EntryEnclosure='<enclosure url="'$BLOG_FEED_URL/$Enclosure_File'" length="'$Enclosure_Length'" type="'$Enclosure_Type'" />'
			fi
		fi
		cat >> "$SCRATCH_FILE".rss2feed <<-EOF
			<item>
				<link>${NB_RSS2ArchivesPath}$NB_EntryPermalink</link>
				<guid isPermaLink="true">${NB_RSS2ArchivesPath}$NB_EntryPermalink</guid>
				<title>$NB_RSS2EntryTitle</title>
				<dc:date>$NB_RSS2EntryTime${BLOG_FEED_TZD}</dc:date>
				<dc:creator>$NB_RSS2EntryAuthor</dc:creator>
				$NB_RSS2EntrySubject
				<description><![CDATA[$NB_RSS2EntryExcerpt]]></description>
				$NB_RSS2EntryEnclosure
			</item>
		EOF
	done
	NB_RSS2Entries=$(< "$SCRATCH_FILE".rss2feed)
	}

	# generate category feed entries
	build_rss_catfeeds(){
	db_categories=(${CAT_LIST[@]})
	if [ ! -z "${db_categories[*]}" ]; then
		for cat_db in ${db_categories[@]}; do
			if [ -f "$NB_DATA_DIR/$cat_db" ]; then
				set_catlink "$cat_db"
				NB_RSS2CatFile=`echo "$category_file" |sed -e 's/[\.]'$NB_FILETYPE'/-rss.'$NB_SYND_FILETYPE'/g'`
				NB_RSS2CatLink="$category_link"
				NB_RSS2CatTitle=`nb_print "$NB_DATA_DIR/$cat_db" 1 |esc_chars`
				nb_msg "$plugins_action $category_dir rss $NB_RSS2Ver feed  ..."
				build_rssfeed "$cat_db"
				make_rssfeed "$BLOG_DIR/$ARCHIVES_DIR/$NB_RSS2CatFile"
			fi
		done
	fi
	}

	nb_msg "$plugins_action rss $NB_RSS2Ver feed ..."
	build_rssfeed nocat
	make_rssfeed "$BLOG_DIR/$NB_RSS2File"
	if [ "$CATEGORY_FEEDS" = 1 ] && [ "$RSS2_CATFEEDS" = 1 ]; then
		build_rss_catfeeds
	fi
fi

# restore chronological order
[ ! -z "$RESTORE_SORTARGS" ] &&
	SORT_ARGS="$RESTORE_SORTARGS"

