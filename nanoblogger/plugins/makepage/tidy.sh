# NanoBlogger tidy plugin, requires program, tidy.
#
# Tidy is an HTML syntax checker and reformatter.
# See the man pages for more information.

# sample code for templates, based off default stylesheet
#
# <div class="sidetitle">
# Validation
# </div>
#
# <div class="side">
# $NB_Tidy
# </div>

# set tidy command
: ${TIDY_CMD:=tidy}

# set additional arguments
: ${TIDY_HTML_ARGS:=-asxhtml -n -utf8}
: ${TIDY_XML_ARGS:=-xml -n -utf8 -wrap 0}

# file to log tidy errors to
TIDY_LOGFILE="$BLOG_DIR/tidy.log"

TIDY_PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/tidy.$NB_FILETYPE"

# display tidy information
tidy_info(){
exitcode="$?"
if [ "$exitcode" = 1 ]; then
	nb_msg "tidy issued warning messages"
elif [ "$exitcode" = 2 ]; then
	nb_msg "tidy issued error messages"
elif [ "$exitcode" != 0 ]; then
	nb_msg "tidy exited with code: $exitcode"
fi
[ ! -N "$MKPAGE_OUTFILE" ] &&
	die "tidy FAILED to modify input"
}

if nb_eval "$TIDY_CMD -v"; then
	if [ ! -f "$TIDY_LOGFILE" ] || [ "$tidylog_restarted" != 1 ]; then
		> "$TIDY_LOGFILE"
		tidylog_restarted=1
	fi
	# detect file's suffix
	TIDY_SUFFIX_VAR="${MKPAGE_OUTFILE##*.}"
	if [ "$TIDY_SUFFIX_VAR" = "$NB_FILETYPE" ]; then
		nb_msg "tidy validating $MKPAGE_OUTFILE ..."
		cat >> "$TIDY_LOGFILE" <<-EOF
		
			tidy validating $MKPAGE_OUTFILE:

		EOF
		$TIDY_CMD $TIDY_HTML_ARGS -m $MKPAGE_OUTFILE >> "$TIDY_LOGFILE" 2>&1
		tidy_info
	fi
	if [ "$TIDY_SUFFIX_VAR" = "$NB_SYND_FILETYPE" ]; then
		nb_msg "tidy validating $MKPAGE_OUTFILE ..."
		cat >> "$TIDY_LOGFILE" <<-EOF

			tidy validating $MKPAGE_OUTFILE:

		EOF
		$TIDY_CMD $TIDY_XML_ARGS -m "$MKPAGE_OUTFILE" >> "$TIDY_LOGFILE" 2>&1
		tidy_info
	fi
	echo '<a href="http://validator.w3.org/check/referer"><img' > "$TIDY_PLUGIN_OUTFILE"
	echo 'src="http://www.w3.org/Icons/valid-xhtml11"' >> "$TIDY_PLUGIN_OUTFILE"
	echo 'alt="Valid XHTML!" /></a>' >> "$TIDY_PLUGIN_OUTFILE"
	NB_Tidy=$(< "$TIDY_PLUGIN_OUTFILE")
fi

