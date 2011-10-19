# NanoBlogger Auto br plugin to convert line breaks to HTML
# 2 line breaks (blank line) = <br /><br />
 
nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" |sed -e '/^$/ s//\<br \/\>\<br \/\>/g'`

