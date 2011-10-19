# Page Formatting plugin that converts mood variables
# to emoticons - controlled by moods.conf file

: ${MOODS_DIR:=$BLOG_DIR/moods}
MOODS_URL="${BASE_URL}moods"
MOODS_CONF="${MOODS_DIR}/moods.conf"

if [ -d "$MOODS_DIR" ]; then
	create_moods(){
	mood_url=`echo "${MOODS_URL//\//\\\\/}\\\\/${mood_img//\//\\\\/}"`
	sed_sub=' <img src="'$mood_url'" alt="'$mood_var'" \/>'
	sed_script='/[ ]'$mood_var'[ ]/ s// '$sed_sub' /g; /[ ]'$mood_var'$/ s// '$sed_sub'/g; /'$mood_var'[ ]/ s//'$sed_sub' /g'
	MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" |sed -e "$sed_script"`
	}

	load_moods(){
	if [ -f "$MOODS_CONF" ]; then
		if [ -z "$mood_lines" ]; then
			mood_lines=(`cat "$MOODS_CONF" |sed -e '/^$/d; /[\#\]/d; /[^ ].*/ s//dummy/g'`)
		fi
		if [ -z "$mood_list" ]; then
			mood_list=(`cat "$MOODS_CONF" |sed -e '/^$/d; /^[\#\]/d'`)
		fi
		moodoffset=0; moodlimit=3
		for mood in ${mood_lines[@]}; do
			[ -z "${mood_list[*]:$moodoffset:$moodlimit}" ] &&
				break
			mood_var=`echo "${mood_list[@]:$moodoffset:$moodlimit}" |cut -d" " -f1 | sed -e '/[\*\]/ s//[*]/'`
			mood_img=`echo "${mood_list[@]:$moodoffset:$moodlimit}" |cut -d" " -f3`
			create_moods
			let moodoffset=${moodoffset}+$moodlimit
		done
	fi
	}

	nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
	load_moods
fi

