# NanoBlogger Shortcode YouTube plugin
# e.g. [youtube=http://www.youtube.com/...] -> <object type=... 
# e.g. [youtube]http://www.youtube.com/...[/youtube] -> <object type...
# e.g. [youtube width=425 height=344]http://www.youtube.com/...[/youtube] -> <object type...

# quickly detect youtube shortcode
shortcode_youtube_open="${NB_MetaBody//*[\[]youtube=*/true}"
shortcode_youtube_enclosed="${NB_MetaBody//*[\[]youtube[\]]*[\[]\/youtube*/true}"
shortcode_youtube_encwatts="${NB_MetaBody//*[\[]youtube *[\[]\/youtube*/true}"

# shortocode for url only
sc_youtube_open(){
if [ "$shortcode_youtube_open" = true ]; then
	sc_lines=`echo "$NB_MetaBody" |grep -n "\[youtube\=" |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_youtube_data=`echo "$NB_MetaBody" |sed -e '/\[youtube\=/!d; /[^ ]*.*\[youtube[\=]/ s///g; /\][^ ]*.*/ s///g'`
	sc_lineid=0
	for shortcode_youtube_line in ${shortcode_youtube_data[@]}; do
		youtube_url=; youtubeurlmod_xargs=; shortcode_youtube_output=; shortcode_youtube_sedscript=
		youtube_urlneedsmod="${shortcode_youtube_line//*watch\?v\=*/true}"
		if [ "$youtube_urlneedsmod" = true ]; then
			youtubeurlmod_xargs="&hl=en&fs=1"
			shortcode_youtube_line="${shortcode_youtube_line//watch\?v\=/v/}"
		fi
		[ ! -z "$youtubeurlmod_xargs" ] && shortcode_youtube_line="${shortcode_youtube_line}$youtubeurlmod_xargs"
		youtube_url=`echo "$shortcode_youtube_line" |sed -e '/\&/ s//\\\&amp\\\;/g; /\&amp\;\&amp\;/ s//\\\&amp\\\;/g'`
		youtube_url=`echo "${youtube_url//\//\\\\/}\\\\"`
		shortcode_youtube_output=' <object type="application\/x-shockwave-flash" data="'$youtube_url'" width="425" height="344"><param name="movie" value="'$youtube_url'" \/><param name="allowFullScreen" value="true" \/><\/object>'
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_youtube_sedscript='s/[ ]\[youtube\=http\:\/\/*.*[A-Za-z0-9]\]/ '$shortcode_youtube_output' /; '$sc_id' s/[ ]\[youtube\=http\:\/\/*.*[A-Za-z0-9]\]$/ '$shortcode_youtube_output'/; '$sc_id' s/^\[youtube\=http\:\/\/*.*[A-Za-z0-9]\] /'$shortcode_youtube_output' /; '$sc_id' s/^\[youtube\=http\:\/\/*.*[A-Za-z0-9]\]$/'$shortcode_youtube_output'/'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_youtube_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

# shortocode for url enclosed
sc_youtube_enclosed(){
if [ "$shortcode_youtube_enclosed" = true ]; then
	sc_lines=`echo "$NB_MetaBody" |grep -n "\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\]" |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_youtube_data=`echo "$NB_MetaBody" |sed -e '/\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\]/!d; /[^ ]*.*\[youtube\]/ s///g; /\[\/youtube\]*.*/ s///g'`
	sc_lineid=0
	for shortcode_youtube_line in ${shortcode_youtube_data[@]}; do
		youtube_url=; youtubeurlmod_xargs=; shortcode_youtube_output=; shortcode_youtube_sedscript=
		youtube_urlneedsmod="${shortcode_youtube_line//*watch\?v\=*/true}"
		if [ "$youtube_urlneedsmod" = true ]; then
			youtubeurlmod_xargs="&hl=en&fs=1"
			shortcode_youtube_line="${shortcode_youtube_line//watch\?v\=/v/}"
		fi
		[ ! -z "$youtubeurlmod_xargs" ] && shortcode_youtube_line="${shortcode_youtube_line}$youtubeurlmod_xargs"
		youtube_url=`echo "$shortcode_youtube_line" |sed -e '/\&/ s//\\\&amp\\\;/g; /\&amp\;\&amp\;/ s//\\\&amp\\\;/g'`
		youtube_url=`echo "${youtube_url//\//\\\\/}\\\\"`
		shortcode_youtube_output=' <object type="application\/x-shockwave-flash" data="'$youtube_url'" width="425" height="344"><param name="movie" value="'$youtube_url'" \/><param name="allowFullScreen" value="true" \/><\/object>'
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_youtube_sedscript=''$sc_id' s/[ ]\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\]/ '$shortcode_youtube_output' /; '$sc_id' s/[ ]\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\]$/ '$shortcode_youtube_output'/; '$sc_id' s/^\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\] /'$shortcode_youtube_output' /; '$sc_id' s/^\[youtube\]http\:\/\/*.*[A-Za-z0-9]\[\/youtube\]$/'$shortcode_youtube_output'/'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_youtube_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

# shortcode for url with attributes
sc_youtube_encwatts(){
if [ "$shortcode_youtube_encwatts" = true ]; then
	sc_lines=`echo "$NB_MetaBody" |grep -n "\[youtube " |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_youtube_data=`echo "$NB_MetaBody" |sed -e '/\[youtube /!d; /[^ ].*\[youtube / s///; /\[\/youtube\]*.*/ s///; /[ ]/ s//_SHORTCODESPACER_/g'`
	sc_lineid=0
	for shortcode_youtube_line in ${shortcode_youtube_data[@]}; do
		youtube_url=; youtubeurlmod_xargs=; shortcode_youtube_atts=; shortcode_youtube_output=; shortcode_youtube_sedscript=
		shortcode_youtube_line="${shortcode_youtube_line//_SHORTCODESPACER_/ }"
		youtube_url=`echo "$shortcode_youtube_line" |sed -e '/[^ ].*\]/ s///'`
		youtube_urlneedsmod="${youtube_url//*watch\?v\=*/true}"
		if [ "$youtube_urlneedsmod" = true ]; then
			youtubeurlmod_xargs="&hl=en&fs=1"
			youtube_url="${youtube_url//watch\?v\=/v/}"
		fi
		[ ! -z "$youtubeurlmod_xargs" ] && youtube_url="${youtube_url}$youtubeurlmod_xargs"
		youtube_url=`echo "$youtube_url" |sed -e '/\&/ s//\\\&amp\\\;/g; /\&amp\;\&amp\;/ s//\\\&amp\\\;/g'`
		youtube_url=`echo "${youtube_url//\//\\\\/}\\\\"`
		shortcode_youtube_atts="${shortcode_youtube_line//*\[youtube[ ]}"; shortcode_youtube_atts="${shortcode_youtube_atts//\]*}"
		for sc_youtube_attr in ${shortcode_youtube_atts[*]}; do
			sc_youtube_attr_name="${sc_youtube_attr//\=*}"; sc_youtube_attr_val="${sc_youtube_attr//*\=}"; sc_youtube_attr_val="${sc_youtube_attr_val//\"/}"
			[ "$sc_youtube_attr_name" = width ] && youtube_width="$sc_youtube_attr_val"
			[ "$sc_youtube_attr_name" = height ] && youtube_height="$sc_youtube_attr_val"
		done
		shortcode_youtube_output=' <object type="application\/x-shockwave-flash" data="'$youtube_url'" width="'$youtube_width'" height="'$youtube_height'"><param name="movie" value="'$youtube_url'" \/><param name="allowFullScreen" value="true" \/><\/object>'
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_youtube_sedscript=''$sc_id' s/[ ]\[youtube [^ ].*\][^ ].*\[\/youtube\]/ '$shortcode_youtube_output' /; '$sc_id' s/[ ]\[youtube *.*\][^ ].*\[\/youtube\]$/ '$shortcode_youtube_output'/; '$sc_id' s/^\[youtube *.*\][^ ].*\[\/youtube\] /'$shortcode_youtube_output' /; '$sc_id' s/^\[youtube *.*\][^ ].*\[\/youtube\]$/'$shortcode_youtube_output'/'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_youtube_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

for sc_youtube in sc_youtube_open sc_youtube_enclosed sc_youtube_encwatts; do
	$sc_youtube
done

