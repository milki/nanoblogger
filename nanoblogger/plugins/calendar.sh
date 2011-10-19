# NanoBlogger Calendar Plugin, requires the cal command.
# converts the output of cal to an HTML Table and creates links of entries
#
# sample code for template - based off default stylesheet
#
# <div class="side">
# $NB_Calendar
# </div>

make_calendar(){
cal_year="$1"
cal_month="$2"
cal_file="$3"
: ${CAL_CMD:=cal}
mkdir -p `dirname "$cal_file"`
# halt if cal command fails
nb_eval "$CAL_CMD" || continue
PLUGIN_CALENDAR=1
[ -z "$cal_year" ] &&
	cal_year=`date +%Y`
[ -z "$cal_month" ] &&
	cal_month=`date +%m`
query_cal=$cal_year.$cal_month
[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
CAL_HEAD=`echo "$CALENDAR" |sed 1q`
CAL_HEAD=${CAL_HEAD//[ ][ ]/}; CAL_HEAD=${CAL_HEAD%%[ ][ ]}; CAL_HEAD=${CAL_HEAD##[ ][ ]}
WEEK_DAYS=(`echo "$CALENDAR" |sed -n 2p`)
DAYS=`echo "$CALENDAR" |sed 1,2d`
NUM_DAY_LINES=(`echo "$DAYS" |grep -n "[0-9]" |cut -d":" -f 1`)
nb_msg "$plugins_action weblog calendar for $CAL_HEAD ..."
[[ "$cal_file" = "$BLOG_DIR/$PARTS_DIR/cal.$NB_FILETYPE" ]] &&
	set_baseurl "./"
query_db "$query_cal"
CALMONTH_LIST=(${DB_RESULTS[*]})

echo '<table border="0" cellspacing="4" cellpadding="0" summary="Calendar">' > "$cal_file"
if [ "$MONTH_ARCHIVES" = 1 ] && [ "${#CALMONTH_LIST[*]}" -gt 0 ]; then
	# create link to month's archive
	set_monthlink ${query_cal//\./-}
	echo '<caption class="calendarhead"><a href="'${BASE_URL}$ARCHIVES_DIR/$NB_ArchiveMonthLink'">'$CAL_HEAD'</a></caption>' >> "$cal_file"
else
	echo '<caption class="calendarhead">'$CAL_HEAD'</caption>' >> "$cal_file"
fi
echo '<tr>' >> "$cal_file"
for wd in ${WEEK_DAYS[@]}; do
	echo '<th><span class="calendarday">'$wd'</span></th>' >> "$cal_file"
done
echo '</tr>' >> "$cal_file"
for line in ${NUM_DAY_LINES[@]}; do
	DN_LINES=`echo "$DAYS" |sed -n "$line"p`
	echo '<tr>' >> "$cal_file"
	DNLINES_ENDSPACE=`echo "$DN_LINES" |grep -c '  $'`
	[ "$DNLINES_ENDSPACE" -lt 1 ] &&
		echo "$DN_LINES" | sed -e '/  [ \t]/ s//<td><\/td>\ /g; /[0-9]/ s///g; /  $/ s///g' >> "$cal_file"
	for dn in $DN_LINES; do
		set_link=0
		CALENTRY_LIST=(`for day in ${CALMONTH_LIST[@]}; do echo $day; done |grep $dn`)
		for entry in ${CALENTRY_LIST[@]}; do
			entry_year=${entry:0:4}
			entry_month=${entry:5:2}
			entry_day=${entry:8:2}
			entry_day=`echo $entry_day |sed -e '/^0/ s///g'`
			if [ "$cal_year$cal_month$dn" = "$entry_year$entry_month$entry_day" ] ; then
				set_link=1
				NB_EntryID=$x_id${entrylink_var//[\/]/-}
				if [ "$MONTH_ARCHIVES" != 1 ] && [ "$ENTRY_ARCHIVES" = 1 ]; then
					set_entrylink "$entry"
				else
					set_entrylink "$entry" altlink
				fi
				dn='<a href="'${ARCHIVES_PATH}$NB_EntryPermalink'">'$dn'</a>'
				echo '<td><span class="calendar">'$dn'</span></td>' >> "$cal_file"
			fi
		done
		if [ "$set_link" != 1 ] ; then
			echo '<td><span class="calendar">'$dn'</span></td>' >> "$cal_file"
		fi
	done
	DNLINES_BEGINSPACE=`echo "$DN_LINES" |grep -c '^  '`
	[ "$DNLINES_BEGINSPACE" -lt 1 ] &&
		echo "$DN_LINES" | sed -e '/  [ \t]/ s//<td><\/td>\ /g; /[0-9]/ s///g; /^  / s///g' >> "$cal_file"
	echo '</tr>' >> "$cal_file"
done
echo '</table>' >> "$cal_file"
CALENDAR=
}

make_calendar "`date +%Y`" "`date +%m`" "$BLOG_DIR/$PARTS_DIR/cal.$NB_FILETYPE"
# The main calendar's place-holder for the templates
NB_Calendar=$(< "$BLOG_DIR/$PARTS_DIR/cal.$NB_FILETYPE")
