# NanoBlogger Auto <br> tag plugin that converts line breaks to HTML
# 2 line breaks (blank line) = <br /><br />

# nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
NB_MetaBody=`echo "$NB_MetaBody" |sed -e '/^$/ s//\<br \/\>\<br \/\>/g'`

