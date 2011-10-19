# Category archive plugin: Include Listings
# generates entries listings for inclusion elsewhere on a site.

# define templates
CATENTRY_INC_TEMPLATE="category_inc_entry.htm"
CATEGORY_INC_TEMPLATE="category_inc_archive.htm"

# define settings
: ${MAX_CATPAGE_INC_ENTRIES:=$MAX_PAGE_ENTRIES}
: ${NB_INC_INDEXFILE:=index-include.$NB_FILETYPE}

category_inc_file="$category_dir/$NB_INC_INDEXFILE"
nb_msg "generating simple include listings ..."
# Nijel: generate simple listing
paginate all "$cat_arch" "$MAX_CATPAGE_INC_ENTRIES" "$CATEGORY_INC_TEMPLATE" \
	"$CATENTRY_INC_TEMPLATE" "$BLOG_DIR/$ARCHIVES_DIR/" "$category_inc_file"

