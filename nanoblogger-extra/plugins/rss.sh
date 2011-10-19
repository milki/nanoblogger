# NanoBlogger RSS 1.0 Feed Plugin

# concatenate modification variables
FEEDMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Move_EntryFile$USR_TITLE"

# set URL for syndication feed
[ ! -z "$BLOG_URL" ] &&
	: ${BLOG_FEED_URL:=$BLOG_URL}

# set timezone used for feed
: ${BLOG_FEED_TZD:=$BLOG_TZD}
# use entry excerpts from entry excerpts plugin
# (excerpts plugin must be enabled to work)
: ${ENTRY_EXCERPTS:=0}

# limit number of items to include in feed
: ${BLOG_FEED_ITEMS:=$FEED_ITEMS}
: ${BLOG_FEED_ITEMS:=10}
: ${RSS_ITEMS:=$BLOG_FEED_ITEMS}
# build rss feeds for categories (0/1 = off/on)
: ${RSS_CATFEEDS:=0}

# output filename of rss feed
NB_RSSFile="index.$NB_SYND_FILETYPE"
# rss feed version
NB_RSSVer="1.0"

NB_RSSModDate=`date "+%Y-%m-%dT%H:%M:%S${BLOG_FEED_TZD}"`

# set link to archives
NB_RSSArchivesPath="$BLOG_FEED_URL/$ARCHIVES_DIR/"

# set link for main template
set_baseurl './'
NB_RSSFeedLink='<a href="'${BASE_URL}$NB_RSSFile'" class="feed-small">RSS</a>'

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
	NB_RSSAuthor=`echo "$BLOG_AUTHOR" |esc_chars`

# make rss feed
	make_rssfeed(){
	MKPAGE_OUTFILE="$1"
	mkdir -p `dirname "$MKPAGE_OUTFILE"`
	BLOG_FEED_URLFILE="$BLOG_FEED_URL/$NB_RSSFile"
	NB_RSSTitle="$BLOG_FEED_TITLE"
	[ ! -z "$NB_RSSCatTitle" ] &&
		NB_RSSTitle="$template_catarchives $NB_RSSCatTitle | $BLOG_FEED_TITLE"
	if [ ! -z "$NB_RSSCatLink" ]; then
		NB_RSSFile="$ARCHIVES_DIR/$NB_RSSCatFile"
		BLOG_FEED_URLFILE="$BLOG_FEED_URL/$NB_RSSFile"
	fi

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
		<!DOCTYPE rdf:RDF [
		<!ENTITY % HTMLlat1 PUBLIC
		 "-//W3C//ENTITIES Latin 1 for XHTML//EN"
		 "http://www.w3.org/TR/xhtml1/DTD/xhtml-lat1.ent">
		]>
		<rdf:RDF
		 xmlns="http://purl.org/rss/1.0/"
		 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		 xmlns:dc="http://purl.org/dc/elements/1.1/"
		 xmlns:content="http://purl.org/rss/1.0/modules/content/"
		 xmlns:admin="http://webns.net/mvcb/"
		>
		<channel rdf:about="$BLOG_FEED_URLFILE">
			<title>$NB_RSSTitle</title>
			<link>$BLOG_FEED_URL</link>
			<description>$BLOG_DESCRIPTION</description>
			<dc:language>$BLOG_FEED_LANG</dc:language>
			<dc:creator>$NB_RSSAuthor</dc:creator>
			<dc:date>$NB_RSSModDate</dc:date>
			<admin:generatorAgent rdf:resource="http://nanoblogger.sourceforge.net" />
			<items>
				<rdf:Seq>
					$NB_RSSItems
				</rdf:Seq>
			</items>
		</channel>
		$NB_RSSEntries
		</rdf:RDF>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	# load makepage tidy plugin
	load_plugins makepage/tidy.sh
	}

	# generate feed entries
	build_rssfeed(){
	db_catquery="$1"
	query_db all "$db_catquery" limit "$RSS_ITEMS"
	ARCHIVE_LIST=(${DB_RESULTS[@]})
	RSS_SEQFILE="$SCRATCH_FILE.rss_seq"
	> "$SCRATCH_FILE".rssfeed
	> "$RSS_SEQFILE"
	for entry in ${ARCHIVE_LIST[@]}; do
		NB_RSSEntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
		set_entrylink "$entry"
		load_entry "$NB_DATA_DIR/$entry" ALL
		echo '<rdf:li rdf:resource="'${NB_RSSArchivesPath}$NB_EntryPermalink'" />' >> "$RSS_SEQFILE"
		# non-portable find command!
		#NB_RSSEntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS${BLOG_FEED_TZD}"`
		NB_RSSEntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		NB_RSSEntryAuthor=`echo "$NB_EntryAuthor" |esc_chars`
		[ -z "$NB_RSSEntryTitle" ] && NB_RSSEntryTitle="$notitle"
		NB_RSSEntrySubject=; cat_title=; oldcat_title=
		rssentry_wcatids=`grep "$entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
		rssentry_catids="${rssentry_wcatids##*\>}"
		[ "$rssentry_wcatids" = "$rssentry_catids" ] &&
			rssentry_catids=
		for rss_catnum in ${rssentry_catids//\,/ }; do
			cat_title=`sed 1q "$NB_DATA_DIR"/cat_"$rss_catnum.$NB_DBTYPE"`
			[ "$cat_title" != "$oldcat_title" ] &&
				cat_title="$oldcat_title $cat_title"
			oldcat_title="$cat_title,"
		done
		if [ ! -z "$cat_title" ]; then
			cat_title=`echo "${cat_title##\,}" |esc_chars`
			NB_RSSEntrySubject=`echo '<dc:subject>'$cat_title'</dc:subject>'`
		fi
		if [ "$ENTRY_EXCERPTS" = 1 ] && [ ! -z "$NB_EntryExcerpt" ]; then
			#NB_RSSEntryExcerpt=`echo "$NB_EntryExcerpt" |esc_chars`
			NB_RSSEntryExcerpt="$NB_EntryExcerpt"
		else
			#NB_RSSEntryExcerpt=`echo "$NB_MetaBody" |esc_chars`
			NB_RSSEntryExcerpt="$NB_MetaBody"
		fi
		cat >> "$SCRATCH_FILE".rssfeed <<-EOF
			<item rdf:about="${NB_RSSArchivesPath}$NB_EntryPermalink">
				<link>${NB_RSSArchivesPath}$NB_EntryPermalink</link>
				<title>$NB_RSSEntryTitle</title>
				<dc:date>$NB_RSSEntryTime${BLOG_FEED_TZD}</dc:date>
				<dc:creator>$NB_RSSEntryAuthor</dc:creator>
				$NB_RSSEntrySubject
				<description><![CDATA[$NB_RSSEntryExcerpt]]></description>
			</item>
		EOF
	done
	NB_RSSItems=$(< "$RSS_SEQFILE")
	NB_RSSEntries=$(< "$SCRATCH_FILE".rssfeed)
	}

	# generate category feed entries
	build_rss_catfeeds(){
	db_categories=(${CAT_LIST[*]})
	if [ ! -z "${db_categories[*]}" ]; then
		for cat_db in ${db_categories[@]}; do
			if [ -f "$NB_DATA_DIR/$cat_db" ]; then
				set_catlink "$cat_db"
				NB_RSSCatTitle=`sed 1q "$NB_DATA_DIR/$cat_db" |esc_chars`
				NB_RSSCatFile=`chg_suffix "$category_file" $NB_SYND_FILETYPE`
				NB_RSSCatLink="$category_link"
				nb_msg "$plugins_action rss $NB_RSSVer feed for category ..."
				build_rssfeed "$cat_db"
				make_rssfeed "$BLOG_DIR/$ARCHIVES_DIR/$NB_RSSCatFile"
			fi
		done
	fi
	}

	nb_msg "$plugins_action rss $NB_RSSVer feed ..."
	build_rssfeed nocat
	make_rssfeed "$BLOG_DIR/$NB_RSSFile"
	if [ "$CATEGORY_FEEDS" = 1 ] && [ "$RSS_CATFEEDS" = 1 ]; then
		build_rss_catfeeds
	fi
fi

# restore chronological order
[ ! -z "$RESTORE_SORTARGS" ] &&
	SORT_ARGS="$RESTORE_SORTARGS"

