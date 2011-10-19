# NanoBlogger Base-URL Shortcode  Plugin
# converts [base-url] to relative path
#
# e.g. [base-url] -> "./" or "../"

# quickly detect baseurl shortcode
oldscode_baseurl_specified="${NB_MetaBody//*[\%]base\_url[\%]*/true}"
shortcode_baseurl_specified="${NB_MetaBody//*[\[]base?url[\]]*/true}"

# old shortocode for base-url
# e.g. %base_url% -> "./" or "../"
oldsc_baseurl_specified(){
if [ "$oldscode_baseurl_specified" = true ]; then
	shortcode_baseurl_output=; shortcode_baseurl_sedscript=
	# don't change BASE_URL of entries
	[ ! -z "$weblogpage_plugin" ] && set_baseurl "" "$BLOGPAGE_OUTFILE"
	baseurl_link="${BASE_URL//\//\\/}"
	shortcode_baseurl_output="$baseurl_link"
	shortcode_baseurl_sedscript='s/\%base\_url\%/'$shortcode_baseurl_output'/'
	NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_baseurl_sedscript"`
fi
}

# shortocode for base-url
sc_baseurl_specified(){
if [ "$shortcode_baseurl_specified" = true ]; then
	shortcode_baseurl_output=; shortcode_baseurl_sedscript=
	# don't change BASE_URL of entries
	[ ! -z "$weblogpage_plugin" ] && set_baseurl "" "$BLOGPAGE_OUTFILE"
	baseurl_link="${BASE_URL//\//\\/}"
	shortcode_baseurl_output="$baseurl_link"
	shortcode_baseurl_sedscript='s/\[base.url\]/'$shortcode_baseurl_output'/g'
	NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_baseurl_sedscript"`
fi
}

for sc_baseurl in oldsc_baseurl_specified sc_baseurl_specified; do
	$sc_baseurl
done
