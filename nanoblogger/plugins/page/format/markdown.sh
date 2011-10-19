# NanoBlogger plugin to filter page content through markdown
# Markdown is documented and implemented at
#   <URL:http://daringfireball.net/projects/markdown/>

: ${MARKDOWN_CMD:=markdown}
: ${MARKDOWN_OPTS:= }

nb_eval "$MARKDOWN_CMD" && MARKDOWN_INPATH=true

if [ "$MARKDOWN_INPATH" = "true" ]; then
	nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
	MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" | ${MARKDOWN_CMD} ${MARKDOWN_OPTS}`
else
	die "$nb_plugin: $plugins_abort"
fi

