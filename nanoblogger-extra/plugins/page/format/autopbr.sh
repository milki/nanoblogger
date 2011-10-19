# NanoBlogger Auto P break plugin to convert line breaks to HTML
# 2 line breaks (blank line) = <p></p>

nb_msg "$plugins_textformataction `basename $nb_plugin` ..."
MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" |sed -e '/^$/ s//\<p\>\<\/p\>/g'`

