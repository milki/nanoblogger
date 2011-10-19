# Module for configuration file management
# Last modified: 2008-08-04T15:48:20-04:00

# --- WARNING ---
# config variables that must always load

# automatically set time zone using GNU specific, 'date +%z'
tzd_hhmm=`date +%z`
tzd_hh=${tzd_hhmm:0:3}; tzd_mm=${tzd_hhmm:3:5}
AUTO_TZD=${tzd_hh}:${tzd_mm}
# ---

# loads global config
load_globals(){
# always load global configs
[ -f "$NB_CFG_DIR/nb.conf" ] && . "$NB_CFG_DIR/nb.conf"
# check for user's .nb.conf in their home directory
[ -f "$HOME/.nb.conf" ] && . "$HOME/.nb.conf"
# default language definition
: ${NB_LANG:=en}
}

# loads global and user configurations
load_config(){
# set temp directory
NB_TEMP_DIR="/tmp"
# prompt to use when asking something.
NB_PROMPT=": "
# set deprecated BASE_DIR for temporary compatibility
BASE_DIR="$NB_BASE_DIR"
load_globals
# allow user specified weblog directories 
[ ! -z "$USR_BLOGDIR" ] && BLOG_DIR="$USR_BLOGDIR"
# auto-detect blog.conf from our CWD
[ -z "$USR_BLOGDIR" ] || [ "$USR_BLOGDIR" = "./" ] && [ -f "$PWD/blog.conf" ] &&
	BLOG_DIR="$PWD"
BLOG_DIR="${BLOG_DIR%%\/}" # remove trailing "/"
# export BLOG_DIR for the benefit of other components
export BLOG_DIR
: ${BLOG_CONF:="$BLOG_DIR/blog.conf"}
# allow user specified weblog config files
[ -f "$USR_BLOGCONF" ] && BLOG_CONF="$USR_BLOGCONF"
# load weblog config file
[ -f "$BLOG_CONF" ] && . "$BLOG_CONF"
# set data directory
[ -d "$BLOG_DIR" ] && NB_DATA_DIR="$BLOG_DIR/data"
# allow user specified weblog data directories
[ ! -z "$USR_DATADIR" ] && NB_DATA_DIR="$USR_DATADIR"
# set template directory
: ${NB_TEMPLATE_DIR:=$BLOG_DIR/templates}
# allow user specified template directories
[ ! -z "$USR_TEMPLATE_DIR" ] && NB_TEMPLATE_DIR="$USR_TEMPLATE_DIR"
# where main plugins are located and run by default
: ${PLUGINS_DIR:=$NB_BASE_DIR/plugins}
# default location for user plugins
: ${USR_PLUGINSDIR:=$BLOG_DIR/plugins}
# default articles suffix
: ${ARTICLES_SUFFIX:=txt}

# --- WARNING ---
# changing the following requires manually modifying
# the weblog directory structure

# load user defined directory to store archives
ARCHIVES_DIR="$BLOG_ARCHIVES_DIR"
# default directory to store archives of weblog
[ -z "$ARCHIVES_DIR" ] && ARCHIVES_DIR=archives
# load user defined directory to store cached data
CACHE_DIR="$BLOG_CACHE_DIR"
# default directory to store cached data of weblog
[ -z "$CACHE_DIR" ] && CACHE_DIR=cache
# load user defined directory to store parts
PARTS_DIR="$BLOG_PARTS_DIR"
# default directory to store parts of weblog
[ -z "$PARTS_DIR" ] && PARTS_DIR=parts
# default directory to store articles of weblog
[ -z "$ARTICLES_DIR" ] && ARTICLES_DIR=articles

# letter to prepend to entry's html id tag
# WARNING: effects permanent links
# load user defined id tag
x_id="$BLOG_ENTRYID_TAG"
: ${x_id:=e}
# ---

# default verbosity, 0 = silent
: ${VERBOSE:=1}
# default to $USER for author
: ${BLOG_AUTHOR:=$USER}
# allow user specified author names
[ ! -z "$USR_AUTHOR" ] && BLOG_AUTHOR="$USR_AUTHOR"
# default to $BROWSER then lynx for browser
[ -z "$NB_BROWSER" ] && [ ! -z "$BROWSER" ] &&
	NB_BROWSER="$BROWSER"
: ${NB_BROWSER:=lynx}
# export NB_BROWSER for the benefit of other components
export NB_BROWSER
# smart defaults for date locale
if [ -n "$LC_ALL" ]; then
	: ${DATE_LOCALE:=$LC_ALL}
elif [ -n "$LC_TIME" ]; then
	: ${DATE_LOCALE:=$LC_TIME}
else
	: ${DATE_LOCALE:=$LANG}
fi
# default date command
: ${DATE_CMD:=date}
# default data file date format
: ${DB_DATEFORMAT:="%Y-%m-%dT%H_%M_%S"}
# default to $EDITOR first then vi
[ -z "$NB_EDITOR" ] && [ ! -z "$EDITOR" ] &&
	NB_EDITOR="$EDITOR"
: ${NB_EDITOR:=vi}
# export NB_EDITOR for the benefit of other components
export NB_EDITOR
# cleanup EDITOR/NB_EDITOR & create NB_EDITORNAME for templates
if [ -z "$NB_EDITORNAME" ]; then
	NB_EDITORNAME="${NB_EDITOR//*\// }"
	NB_EDITORNAME="${NB_EDITORNAME// -*/}"
fi
# default file creation mask
[ -z "$NB_UMASK" ] && NB_UMASK=`umask`
# default to txt for datatype suffix
: ${NB_DATATYPE:=txt}
# default to db for database suffix
: ${NB_DBTYPE:=db}
# default to html for page suffix
: ${NB_FILETYPE:=html}

# --- WARNING ---
# changing the following requires manually modifying
# *all* existing entry data files!

# default metadata marker (a.k.a. spacer)
: ${METADATA_MARKER:=-----}
# default metadata close var (e.g. 'END-----')
: ${METADATA_CLOSEVAR:=END-----}
# depecrated METADATA_CLOSETAG here for transitional purposes only
: ${METADATA_CLOSETAG:=$METADATA_CLOSEVAR}
# ---

# default to raw processing for page content
: ${PAGE_FORMAT:=raw}
# default to raw processing for entry body
: ${ENTRY_FORMAT:=raw}
# default to xml for feed suffix
: ${NB_SYND_FILETYPE:=xml}
# default to AUTO_TZD for iso dates
: ${BLOG_TZD:=$AUTO_TZD}
# defaults to all for query mode
: ${QUERY_MODE:=all}
# set default query mode for all operations
: ${NB_QUERY:=$QUERY_MODE}
# set default query for main page
: ${MAINPAGE_QUERY:=max}
# defaults for maximum entries to display on each page
: ${MAX_ENTRIES:=10}
: ${MAX_PAGE_ENTRIES:=$MAX_ENTRIES}
: ${MAX_CATPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
: ${MAX_MONTHPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
: ${MAX_MAINPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
# defaults for index file name
: ${NB_INDEXFILE:=index.$NB_FILETYPE}
# check if we need to append directory index file to links
: ${SHOW_INDEXFILE:=1}
if [ "$SHOW_INDEXFILE" = 1 ]; then
	NB_INDEX=$NB_INDEXFILE
else
	NB_INDEX=""
fi
# default for page navigation symbols (HTML entities)
: ${NB_NextPage:=&#62;} # >
: ${NB_PrevPage:=&#60;} # <
: ${NB_TopPage:=&#47;&#92;} # /\
: ${NB_EndPage:=&#92;&#47;} # \/
# default to auto cache management
: ${BLOG_CACHEMNG:=1}
# default for maximum entries to save in cache
[ -z "$MAX_CACHE_ENTRIES" ] &&
	let MAX_CACHE_ENTRIES=${MAX_ENTRIES}*2
# default chronological order for archives
: ${CHRON_ORDER:=1}
# determine sort order (-u required)
if [ "$CHRON_ORDER" = 1 ]; then
	SORT_ARGS="-ru"
else
	SORT_ARGS="-u"
fi
# override configuration's interactive mode
[ ! -z "$USR_INTERACTIVE" ] &&
	BLOG_INTERACTIVE="$USR_INTERACTIVE"
# default for showing permanent links
: ${SHOW_PERMALINKS:=1}
# deprecated PERMALINKS here for transitional purposes only
: ${PERMALINKS:=$SHOW_PERMALINKS}
# default for showing category links
: ${SHOW_CATLINKS:=1}
# depecrated CATEGORY_LINKS here for tansitional purposes only
: ${CATEGORY_LINKS:=$SHOW_CATLINKS}
# default for category feeds - leave unset
: ${CATEGORY_FEEDS:=}
# default for friendly links
: ${FRIENDLY_LINKS:=1}
# default limit for # of link title characters
: ${MAX_TITLEWIDTH:=150}
# default for archives configuration
: ${ENTRY_ARCHIVES:=0}
: ${MONTH_ARCHIVES:=1}
: ${DAY_ARCHIVES:=0}
# default for archives data
: ${CATARCH_DATATYPE:=TITLE}
: ${MONTHARCH_DATATYPE:=ALL}
: ${DAYARCH_DATATYPE:=ALL}
}

# deconfigure, clear some auto-default variables
deconfig(){ ARCHIVES_DIR=; CACHE_DIR=; NB_DATA_DIR=; NB_TEMPLATES_DIR=; NB_TEMP_DIR=; \
	USR_PLUGINSDIR=; PARTS_DIR=; PLUGINS_DIR=; \
	NB_DATATYPE=; NB_DBTYPE=; NB_FILETYPE=; NB_INDEXFILE=; NB_SYND_FILETYPE=; NB_PROMPT=; \
	NB_UMASK=; \
 	BLOG_AUTHOR=; BLOG_CACHEMNG=; BLOG_INTERACTIVE=; BLOG_TZD=; \
	CATEGORY_FEEDS=; CHRON_ORDER=; DATE_CMD=; DATE_LOCALE=; FRIENDLY_LINKS=; \
	MAINPAGE_QUERY=; MAX_ENTRIES=; MAX_CACHE_ENTRIES=; MAX_CATPAGE_ENTRIES=; \
	MAX_MAINPAGE_ENTRIES=; MAX_MONTHPAGE_ENTRIES=; MAX_PAGE_ENTRIES=; MAX_TITLEWIDTH=; \
	METADATA_MARKER=; METADATA_CLOSEVAR=; METADATA_CLOSETAG=; \
	ENTRY_FORMAT=; PAGE_FORMAT=; \
	SHOW_INDEXFILE=; SHOW_PERMALINKS=; SHOW_CATLINKS=; SORT_ARGS=; \
	CATARCH_DATATYPE=; DAYARCH_DATATYPE=; MONTHARCH_DATATYPE=; \
	ENTRY_ARCHIVES=; DAY_ARCHIVES=; MONTH_ARCHIVES=; \
	QUERY_MODE=
}

