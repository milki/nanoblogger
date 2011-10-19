# NanoBlogger Fortune plugin, requires the fortune program.

# sample code for templates, based off default stylesheet
#
# <div class="sidetitle">
# Random Fortune
# </div>
#
# <div class="side">
# $NB_Fortune
# </div>

# Fortune command, use "-s" for short fortunes
: ${FORTUNE_CMD:=/usr/games/fortune -s}

PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/fortune.$NB_FILETYPE"

if nb_eval "$FORTUNE_CMD"; then
	nb_msg "$plugins_action fortune ..."
	echo '<div class="fortune">' > "$PLUGIN_OUTFILE"
	$FORTUNE_CMD ${FORTUNE_FILE} \
		|sed -e '/[\<]/ s//\&#60;/g; /[\>]/ s//\&#62;/g; /^$/ s//<br \/>/g; /$/ s//<br \/>/g; /[\$]/ s//\$/g' \
		>> "$PLUGIN_OUTFILE"
	echo '</div>' >> "$PLUGIN_OUTFILE"
	NB_Fortune=$(< "$PLUGIN_OUTFILE")
fi
