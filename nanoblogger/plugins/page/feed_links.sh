# NanoBlogger Page Plugin: Feed links

# update category info
if [ ! -z "$cat_arch" ] && [ "$cat_arch" != "$fdlinksprev_cat_arch" ]; then
	set_catlink "$cat_arch"
fi
fdlinksprev_cat_arch="$cat_arch"

# Atom 1.0
if [ ! -z "$NB_AtomVer" ]; then
	NB_AtomLink="${BASE_URL}atom.$NB_SYND_FILETYPE"
	NB_AtomTitle="Atom $NB_AtomVer"
	if [ "$MKPAGE_TEMPLATE" = "$NB_TEMPLATE_DIR/$CATEGORY_TEMPLATE" ] && [[ "$CATEGORY_FEEDS" = 1 && "$ATOM_CATFEEDS" = 1 ]]; then
		NB_AtomCatFile="${category_file//[\.]$NB_FILETYPE/-atom.$NB_SYND_FILETYPE}"
		NB_AtomLink="${ARCHIVES_PATH}$NB_AtomCatFile"
		NB_AtomTitle="Atom $NB_AtomVer: $NB_ArchiveTitle"
	fi
	NB_AtomAltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/atom+xml"
			title="$NB_AtomTitle"
			href="$NB_AtomLink"
		/>
	EOF
	)
fi

# RSS 2.0
if [ ! -z "$NB_RSS2Ver" ]; then
	NB_RSS2Link="${BASE_URL}rss.$NB_SYND_FILETYPE"
	NB_RSS2Title="RSS $NB_RSS2Ver"
	if [ "$MKPAGE_TEMPLATE" = "$NB_TEMPLATE_DIR/$CATEGORY_TEMPLATE" ] && [[ "$CATEGORY_FEEDS" = 1 && "$RSS2_CATFEEDS" = 1 ]]; then
		NB_RSS2CatFile="${category_file//[\.]$NB_FILETYPE/-rss.$NB_SYND_FILETYPE}"
		NB_RSS2Link="${ARCHIVES_PATH}$NB_RSS2CatFile"
		NB_RSS2Title="RSS $NB_RSS2Ver: $NB_ArchiveTitle"
	fi
	NB_RSS2AltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/rss+xml"
			title="$NB_RSS2Title"
			href="$NB_RSS2Link"
		/>
	EOF
	)
fi

# RSS 1.0
if [ ! -z "$NB_RSSVer" ]; then
	NB_RSSLink="${BASE_URL}index.$NB_SYND_FILETYPE"
	NB_RSSTitle="RSS $NB_RSSVer"
	if [ "$MKPAGE_TEMPLATE" = "$NB_TEMPLATE_DIR/$CATEGORY_TEMPLATE" ] && [[ "$CATEGORY_FEEDS" = 1 && "$RSS_CATFEEDS" = 1 ]]; then
		NB_RSSCatFile=`chg_suffix "$category_file" $NB_SYND_FILETYPE`
		NB_RSSLink="${ARCHIVES_PATH}$NB_RSSCatFile"
		NB_RSSTitle="RSS $NB_RSSVer: $NB_ArchiveTitle"
	fi	
	NB_RSSAltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/rss+xml"
			title="$NB_RSSTitle"
			href="$NB_RSSLink"
		/>
	EOF
	)
fi

