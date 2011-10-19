# NanoBlogger Metadata Based Article Manager plugin

# How it works:
# Looks for .txt files in multiple directories.
# Loads metafile (use --draft <file> to create).
# Creates the article using the makepage.htm template.
# Reads alternate title for list from $ARTICLES_TITLE_FILE (1st line).
# Adds links to NB_ArticleLinks.

# sample code for templates, based off the default stylesheet
#
# $NB_ArticleLinks

# set BASE_URL for links to $ATCLSECTION_DIR
set_baseurl "./"

# space seperated list of sub-directories inside $BLOG_DIR, where articles are located
set_articleconf(){
# e.g. ARTICLES_DIR="articles stories poems long\ name\ with\ spaces"
: ${ARTICLES_DIR:=articles}
: ${ARTICLES_SUFFIX:=txt}
: ${ARTICLES_TEMPLATE:=$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE}
: ${ARTICLES_FILTERCMD:=sort}
: ${ARTICLES_TITLE_FILE:=.articles_title.txt}
: ${ARTICLES_FORMAT:=$PAGE_FORMAT}
}

# reset basic configs to allow for multiple article configs
reset_articleconf(){
ARTICLES_SUFFIX=; ARTICLES_TEMPLATE=; ARTICLES_FORMAT=
set_articleconf
}

ARTICLE_PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/article_links.$NB_FILETYPE"

set_articlelink(){
articlelink_var="$1"
#article_title=`sed 1q "$BLOG_DIR/$ATCLSECTION_DIR/$articlelink_var"`
read_metadata TITLE "$BLOG_DIR/$ATCLSECTION_DIR/$articlelink_var"
if [ -z "$METADATA" ]; then
	article_title="$notitle"
else
	article_title="${METADATA//\-/&#150;}"
fi

# new way
article_name=`echo "$articlelink_var" |cut -d"." -f 1`
article_dir=`translit_text "$article_name"`
article_file="$article_dir/index.$NB_FILETYPE"
article_link="$article_dir/$NB_INDEX"

# old way
#article_file=`chg_suffix "$articlelink_var"`
#article_link="$article_file"
}

addalist_name(){
NB_ArticlesListTitle=
# Reads alternate title for list from $ARTICLES_TITLE_FILE (1st line).
[ -f "$BLOG_DIR/$ATCLSECTION_DIR/$ARTICLES_TITLE_FILE" ] &&
	NB_ArticlesListTitle=`nb_print $BLOG_DIR/$ATCLSECTION_DIR/$ARTICLES_TITLE_FILE 1`
# let ARTCLSECTION_DIR define root of articles directory until
# alternate title is created, else create a subtitle for the list
if [ "$ATCLSECTION_DIR" != `echo "$ARTICLES_DIR" |cut -d" " -f 1` ] || [ ! -z "$NB_ArticlesListTitle" ]; then
	if [ ! -f "$BLOG_DIR/$ATCLSECTION_DIR/$ARTICLES_TITLE_FILE" ]; then
		basename "$BLOG_DIR/$ATCLSECTION_DIR" > "$BLOG_DIR/$ATCLSECTION_DIR/$ARTICLES_TITLE_FILE"
		NB_ArticlesListTitle=`nb_print $BLOG_DIR/$ATCLSECTION_DIR/$ARTICLES_TITLE_FILE 1`
	fi
	[ -z "$NB_ArticlesListTitle" ] && NB_ArticlesListTitle="$ATCLSECTION_DIR"
	cat >> "$ARTICLE_PLUGIN_OUTFILE" <<-EOF
		<div class="articleshead">
			$NB_ArticlesListTitle
		</div>
	EOF
fi
NB_ArticlesListTitleHTML=$(< "$ARTICLE_PLUGIN_OUTFILE")
> "$ARTICLE_PLUGIN_OUTFILE"
}

add_articlelink(){
	echo '<!-- '$BLOGPAGE_TITLE' --><a href="'${BASE_URL}$ATCLSECTION_DIR/$article_link'">'$BLOGPAGE_TITLE'</a><br />' >> "$ARTICLE_PLUGIN_OUTFILE"
	}

create_article(){
BLOGPAGE_SRCFILE="$BLOG_DIR/$ATCLSECTION_DIR/$article_srcfile"
BLOGPAGE_OUTFILE="$BLOG_DIR/$ATCLSECTION_DIR/$article_file"
case "$NB_QUERY" in
		all|article|article[a-z])
			[ -z "$cat_num" ] && ! [[ "$NB_UPDATE" == *arch ]] && rm -f "$BLOGPAGE_OUTFILE"
		;;
		*) :
		;;
esac
if [ "$BLOGPAGE_SRCFILE" -nt "$BLOGPAGE_OUTFILE" ]; then
	# set text formatting for page content
	BLOGPAGE_FORMAT="$ARTICLES_FORMAT"
	weblog_page "$BLOGPAGE_SRCFILE" "$ARTICLES_TEMPLATE" "$BLOGPAGE_OUTFILE"
fi
}

cycle_articles_for(){
build_part="$1"
build_list=`cd "$BLOG_DIR/$ATCLSECTION_DIR"; for articles in *.$ARTICLES_SUFFIX; do echo "$articles"; done`
[ "$build_list" = "*.$ARTICLES_SUFFIX" ] && build_list=
article_lines=`echo "$build_list" |grep -n "." |cut -c1-2 |sed -e '/[\:\]/ s///g'`
for line in ${article_lines[@]}; do
	article_line=`echo "$build_list" |sed -n "$line"p`
	article_srcfile=`echo "$article_line"`
	if [ -f "$BLOG_DIR/$ATCLSECTION_DIR/$article_srcfile" ]; then
		set_articlelink "$article_srcfile"
		BLOGPAGE_TITLE="$article_title"
		"$build_part"
	fi
done
}

NB_ArticleLinks="$articles_nolist"
> "$ARTICLE_PLUGIN_OUTFILE"
set_articleconf
for articles_pass in 1 2; do
	for ATCLSECTION_DIR in ${ARTICLES_DIR[@]}; do
		if [ -d "$BLOG_DIR/$ATCLSECTION_DIR" ]; then
			# load articles config file
			ARTICLE_CONF="$BLOG_DIR/$ATCLSECTION_DIR/article.conf"
			if [ -f "$ARTICLE_CONF" ]; then
				reset_articleconf
				. "$ARTICLE_CONF"
			fi
			if [ "$articles_pass" -lt 2 ]; then
				addalist_name
				cycle_articles_for add_articlelink
				NB_ArticleLinksHTML=`$ARTICLES_FILTERCMD "$ARTICLE_PLUGIN_OUTFILE"`
				cat > "$ARTICLE_PLUGIN_OUTFILE" <<-EOF
					$NB_ArticlesListTitleHTML
					<div class="articles">
						$NB_ArticleLinksHTML
					</div>
				EOF
				NB_ArticleLinks=$(< "$ARTICLE_PLUGIN_OUTFILE")
			else
				[ -d "$BLOG_DIR/$ATCLSECTION_DIR" ] &&
					nb_msg "$plugins_action $plugins_articles: $BLOG_DIR/$ATCLSECTION_DIR ..."
				cycle_articles_for create_article
			fi
		fi
	done
done
# clear settings for some page plugins, like markdown.sh
reset_articleconf
