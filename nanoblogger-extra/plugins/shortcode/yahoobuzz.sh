# NanoBlogger Shortcode Yahoo! Buzz plugin
# e.g. [yahoo-buzz] -> <script type=... 

# quickly detect yahoobuzz shortcode
shortcode_yahoobuzz_specified="${NB_MetaBody//*[\[]yahoo?buzz[\]]*/true}"

# shortocode for yahoo buzz
sc_yahoobuzz_specified(){
if [ "$shortcode_yahoobuzz_specified" = true ]; then
	yahoobuzz_link="$BLOG_URL/$ATCLSECTION_DIR/$article_link"
	if [ -z "$article_link" ]; then
		blogdir_sedvar=`echo "${BLOG_DIR//\//\\\\/}\\\\/"`
		yahoobuzz_link="$BLOG_URL/`echo $BLOGPAGE_OUTFILE |sed -e 's/'$blogdir_sedvar'//g'`"
	fi
	yahoobuzz_jscript="http://d.yimg.com/ds/badge2.js"
	sc_lines=`echo "$NB_MetaBody" |grep -n "\[yahoo.buzz\]" |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_yahoobuzz_data=`echo "$NB_MetaBody" |sed -e '/\[yahoo.buzz\]/!d; /[ ]/ s//_SHORTCODESPACER_/g'`
	sc_lineid=0
	for shortcode_yahoobuzz_line in ${shortcode_yahoobuzz_data[@]}; do
		shortcode_yahoobuzz_output=; shortcode_yahoobuzz_sedscript=
		shortcode_yahoobuzz_line="${shortcode_yahoobuzz_line//_SHORTCODESPACER_/ }"
		yahoobuzz_jscript=`echo "$yahoobuzz_jscript" |sed -e '/\&/ s//\\\&amp\\\;/g; /\&amp\;\&amp\;/ s//\\\&amp\\\;/g'`
		yahoobuzz_jscript=`echo "${yahoobuzz_jscript//\//\\\\/}\\\\"`
		yahoobuzz_link=`echo "${yahoobuzz_link//\//\\\\/}\\\\"`
		shortcode_yahoobuzz_output=' <script type="text\/javascript" src="'$yahoobuzz_jscript'" badgetype="medium-votes"\>'$yahoobuzz_link'<\/script\>'
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_yahoobuzz_sedscript=''$sc_id' s/[ ]\[yahoo.buzz\]/ '$shortcode_yahoobuzz_output' /g; '$sc_id' s/[ ]\[yahoo.buzz\]$/ '$shortcode_yahoobuzz_output'/g; '$sc_id' s/^\[yahoo.buzz\] /'$shortcode_yahoobuzz_output' /g; '$sc_id' s/^\[yahoo.buzz\]$/'$shortcode_yahoobuzz_output'/g'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_yahoobuzz_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

for sc_yahoobuzz in sc_yahoobuzz_specified; do
	$sc_yahoobuzz
done
