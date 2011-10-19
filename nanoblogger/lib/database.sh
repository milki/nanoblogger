# Module for database functions
# Last modified: 2008-07-17T22:48:03-04:00

# index related categories by id
index_catids(){
indexcat_item="$1"
indexcat_list=($2)
[ -z "${indexcat_list[*]}" ] &&
	indexcat_list=(`for it_db in "$NB_DATA_DIR"/cat_*.$NB_DBTYPE; do echo ${it_db//*\/}; done`)
[ "$indexcat_list" = "cat_*.$NB_DBTYPE" ] && indexcat_list=
cat_ids=; cat_idnum=
for indexcat_db in ${indexcat_list[@]}; do
	CATDB_RESULTS=($(< "$NB_DATA_DIR/$indexcat_db"))
	for catdb_item in ${CATDB_RESULTS[@]}; do
		db_match=nomatch
		[ "${catdb_item%%>[0-9]*}" = "$indexcat_item" ] &&
			db_match=match
		if [ "$db_match" = match ]; then
			cat_idnum="${indexcat_db/cat\_/}"; cat_idnum="${cat_idnum/\.$NB_DBTYPE/}"
			[ "$cat_idnum" != "$oldcat_idnum" ] && cat_idnum="$oldcat_idnum$cat_idnum"
			oldcat_idnum="$cat_idnum,"
		fi
	done
done
cat_ids=; cat_idnum="${cat_idnum//\, }"
[ ! -z "$cat_idnum" ] && cat_ids=">$cat_idnum"
oldcat_idnum=; cat_idnum=
}

# rebuild main database from scratch
rebuild_maindb(){
	DB_YYYY=${db_query:0:4}
	DB_MM=${db_query:5:2}
	DB_DD=${db_query:8:2}
	: ${DB_YYYY:=[0-9][0-9][0-9][0-9]}
	: ${DB_MM:=[0-9][0-9]}
	: ${DB_DD:=[0-9][0-9]}
	DB_DATE="${DB_YYYY}*${DB_MM}"
	for db_item in "$NB_DATA_DIR"/${DB_DATE}*${DB_DD}*.$NB_DATATYPE; do
		if [ -f "$db_item" ]; then
			entry=${db_item//*\/}
			index_catids "$entry"
			[ -f "$NB_DATA_DIR/$entry" ] &&
				echo "$entry$cat_ids"
		fi
		cat_ids=
	done |sort $db_order > "$SCRATCH_FILE.master.$NB_DBTYPE"
	cp "$SCRATCH_FILE.master.$NB_DBTYPE" "$NB_DATA_DIR/master.$NB_DBTYPE"
}

# split and display entry and categories from raw database results
print_entry(){ echo "${1%%>[0-9]*}"; }
print_cat(){
prcat_entry="${1%%>[0-9]*}"
prcat_catids="${1##*\>}"
[ "$prcat_entry" != "$prcat_catids" ] &&
	echo "$prcat_catids"
}

# get categories for entry from main db
get_catids(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	entry_match=`grep "$db_item" "$db_file"`
	entry_catids=`print_cat "$entry_match"`
	[ "$entry_catids" != "$db_item" ] &&
		echo "$entry_catids"
fi
}

# resort database
resort_db(){
db_file="$1"
db_order="$2"
: ${db_order:=$SORT_ARGS}
if [ -f "$db_file" ]; then
	sort $db_order "$db_file" > "$db_file".tmp && \
	mv "$db_file".tmp "$db_file"
fi
}

# resort category database 
resort_catdb(){
catdb_file="$1"
db_order="$2"
: ${db_order:=$SORT_ARGS}
if [ -f "$catdb_file" ]; then
	catdb_title=`nb_print "$catdb_file" 1`
	echo "$catdb_title" > "$catdb_file".tmp && \
	sed 1d "$catdb_file" |sort "$db_order" >> "$catdb_file".tmp && \
	mv "$catdb_file".tmp "$catdb_file"
fi
}

# resort all the databases
resort_database(){
db_query=; resort_db "$NB_DATA_DIR/master.$NB_DBTYPE"
for cat_db in ${db_categories[*]}; do
	resort_catdb "$NB_DATA_DIR/$cat_db"
done
}

# update entry and it's related categories for main database
update_maindb(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	sed -e '/'$db_item'/d' "$db_file" > "$db_file.tmp" && \
	mv "$db_file".tmp "$db_file"
	index_catids "$db_item"
	[ -f "$NB_DATA_DIR/$db_item" ] &&
		echo "$db_item$cat_ids" >> "$db_file"
fi
}

# update entry and it's related categories for category database
update_catdb(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	sed -e '/'$db_item'/d' "$db_file" > "$db_file.tmp" && \
	mv "$db_file".tmp "$db_file"
	cat_ids=`get_catids "$db_item" "$NB_DATA_DIR/master.$NB_DBTYPE"`
	[ ! -z "$cat_ids" ] && cat_ids=">$cat_ids"
	echo "$db_item$cat_ids" >> "$db_file"
	cat_ids=
fi
}

# update entry for a database
update_db(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	grep_db=`grep "$db_item" "$db_file"`
	[ -z "$grep_db" ] &&
		echo "$db_item" >> "$db_file"
fi
}

# delete an entry from a database
delete_db(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	grep_db=`grep "$db_item" "$db_file"`
	[ ! -z "$grep_db" ] &&
		sed -e '/'$db_item'/d' "$db_file" > "$db_file".tmp && \
		mv "$db_file".tmp "$db_file"
fi
}

rebuild_catdb(){
catdb_file="$1"
if [ -f "$catdb_file" ]; then
	catdb_title=`nb_print "$catdb_file" 1`
	CATDB_RESULTS=(`sed 1d "$catdb_file"`)
	for rbcatdb_item in ${CATDB_RESULTS[@]}; do
		update_catdb "$rbcatdb_item" "$catdb_file"
	done
	resort_catdb "$catdb_file"
fi
}

# search, filter, and create makeshift and main db arrays
query_db(){
db_query="$1"
db_catquery="$2"
db_setlimit="$3"
db_limit="$4"
db_offset="$5"
db_order="$6"
# sanitize db_limit and db_offset
[[ $db_limit = *[a-z]* ]] && db_limit=
[[ $db_offset = *[^0-9]* ]] && db_offset=
: ${db_limit:=$MAX_ENTRIES}
: ${db_limit:=0}; : ${db_offset:=1}
: ${db_order:=$SORT_ARGS}
: ${db_filter:=query}
# adjust offset by 1 for bash arrays (1 = 0)
[ "$db_offset" -ge 1 ] && ((db_offset--))
# allow /'s in queries
db_query="${db_query//\//-}"
# allow range of dates
db_query1="${db_query%%\,*}"
db_query2="${db_query##*\,}"
# get list of categories or accept a user specified list
if [ -z "$db_catquery" ] || [ "$db_catquery" = nocat ]; then
	db_catquery=; db_catvar=`echo "$NB_DATA_DIR"/cat_*.$NB_DBTYPE`
	[ "$db_catvar" != "cat_*.$NB_DBTYPE" ] &&
		db_categories=(`for cat_db in "$NB_DATA_DIR"/cat_*.$NB_DBTYPE; do echo "${cat_db//*\/}"; done`)
else
	db_categories=($db_catquery)
fi
[ "${db_categories[*]}" = "cat_*.$NB_DBTYPE" ] && db_categories=()
query_cmd(){
if [[ "$db_query" = *[\,]* ]]; then
	sed -e '/'$db_query1'.*/,/'$db_query2'.*/!d'
else
	grep "$db_query."
fi
}
# filter_ filters
filter_query(){ query_cmd |cut -d">" -f 1 |sort $db_order; } # allow for empty $db_query
filter_raw(){ query_cmd |sort $db_order; }
# list all entries
list_db(){
# gracefully rebuild main database
if [ ! -f "$NB_DATA_DIR/master.$NB_DBTYPE" ]; then
	db_query=; rebuild_maindb
fi
if [ -z "$db_catquery" ]; then
	grep "[\.]$NB_DATATYPE" "$NB_DATA_DIR/master.$NB_DBTYPE"
else
	# or list entries from cat_n.db
	for cat_db in ${db_categories[*]}; do
		[ -f "$NB_DATA_DIR/$cat_db" ] &&
			grep "[\.]$NB_DATATYPE" "$NB_DATA_DIR/$cat_db"
	done
fi
}
query_data(){
if [ "$db_setlimit" = limit ]; then
	DB_RESULTS=(`list_db |filter_$db_filter`)
	[ "$db_limit" = 0 ] || [ "$db_limit" = -1 ] &&
		db_limit=${#DB_RESULTS[*]}
	DB_RESULTS=(`for db_item in ${DB_RESULTS[@]:$db_offset:$db_limit}; do
			echo $db_item
		done`)
else
	DB_RESULTS=(`list_db |filter_$db_filter`)
fi
}
rebuild_database(){
if [ -z "$db_catquery" ]; then
	db_query=; rebuild_maindb
else
	for cat_db in ${db_categories[*]}; do
		rebuild_catdb "$NB_DATA_DIR/$cat_db"
	done
fi
}
# "main" is a special query that we redirect to MAINPAGE_QUERY
[ "$db_query" = main ] && db_query="$MAINPAGE_QUERY"
# "mode" is a special query that we redirect to $QUERY_MODE
[ "$db_query" = mode ] && db_query="$QUERY_MODE"
# initialize arrays
DB_RESULTS=()
case "$db_query" in
	a|any|all) db_query=; query_data;;
	# create master reference db
	master) db_query=; MASTER_DB_RESULTS=(); MASTER_DB_RESULTS=($(< "$NB_DATA_DIR/master.$NB_DBTYPE"));;
	years) db_query=; YEAR_DB_RESULTS=(); YEAR_DB_RESULTS=(`list_db |cut -c1-4 |filter_query`);;
	months) db_query=; MONTH_DB_RESULTS=(); MONTH_DB_RESULTS=(`list_db |cut -c1-7 |filter_query`);;
	days) db_query=; DAY_DB_RESULTS=(); DAY_DB_RESULTS=(`list_db |cut -c1-10 |filter_query`);;
	max) db_setlimit=limit; db_query=; query_data;;
	rebuild) rebuild_database;;
	*) query_data;;
esac
db_query=; db_filter=; db_order=;
}

# search, filter, and create raw db references
raw_db(){
db_filter=raw
query_db "$1" "$2" "$3" "$4" "$5" "$6"
}

