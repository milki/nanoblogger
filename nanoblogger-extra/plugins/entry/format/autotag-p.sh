# NanoBlogger Auto <p> tag plugin that converts line breaks to HTML
# 2 line breaks (blank line) = <p></p>

# nb_msg "$plugins_textformataction `basename $nb_plugin` ..."
NB_MetaBody=`echo "$NB_MetaBody" |sed -e '/^$/ s//\<p\>\<\/p\>/g'`

