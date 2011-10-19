# Module for error handling
# Last modified: 2006-09-20T13:57:26-04:00

# function to die with a message
die(){
cat <<-EOF
	$@
EOF
exit 1
}

nb_msg(){
if [ "$VERBOSE" != 0 ]; then
	cat <<-EOF
		$@
	EOF
fi
}

