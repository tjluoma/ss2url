#!/bin/zsh
# Purpose: rename screenshot and automatically upload it to Dropbox
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-12-10

NAME="$0:t:r"

zmodload zsh/stat
zmodload zsh/datetime

# http://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Dropbox_logo.svg/200px-Dropbox_logo.svg.png
DB_LOGO="$HOME/Pictures/Logos/Dropbox/Dropbox-200x200.png"

function msg
{
	echo "$NAME: $@"

	growlnotify --sticky --image "$DB_LOGO" --identifier "$NAME" --message "$@" --title "$NAME"
}

if ((! $+commands[dropbox_uploader.sh] ))
then

	# note: if dropbox_uploader.sh is a function or alias, it will come back not found

	msg "dropbox_uploader.sh not found in \$PATH"
	exit 1

fi

##########################################################################################

function do_upload
{
	START_SND='/Applications/Skitch.app/Contents/Resources/PTW_commence.m4a'
	SUCCESS_SND='/Applications/Skitch.app/Contents/Resources/PTW_complete.m4a'
	FAIL_SND='/System/Library/Sounds/Sosumi.aiff'

	[[ -e "$START_SND" ]] && afplay "$START_SND"

	msg "Uploading $FILENAME"

	dropbox_uploader.sh -p upload "$FILENAME" "screenshots/$FILENAME"

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
			# Upload was a success
		[[ -e "$SUCCESS_SND" ]] && afplay "$SUCCESS_SND"

			# Now we need the share URL
		SHARE_URL=`dropbox_uploader.sh share "screenshots/$FILENAME"`

			# Trim the URL to just the URL
		SHARE_URL=`echo $SHARE_URL | sed 's#.*Share link: ##g'`

			# get rid of the original file
		trash "$FILENAME" 2>/dev/null || mv -vf "$FILENAME" "$HOME/.Trash/"

			# put URL on pasteboard
		echo -n "$SHARE_URL" | pbcopy

		echo "$SHARE_URL"

		growlnotify \
			--url "$SHARE_URL" --image "$DB_LOGO" --identifier "$NAME" \
			--message "$SHARE_URL" --title "On Pasteboard:"

	else
		[[ -e "$FAIL_SND" ]] && afplay "$FAIL_SND"

		msg "Failed to upload $FILENAME"
	fi

}

##########################################################################################

DIR=`defaults read com.apple.screencapture location 2>/dev/null`

[[ "$DIR" == "" ]] && DIR="$HOME/Desktop"

cd "$DIR"

PREFIX=`defaults read com.apple.screencapture name 2>/dev/null`

[[ "$PREFIX" == "" ]] && PREFIX='Screen Shot'

SUFFIX=`defaults read com.apple.screencapture type 2>/dev/null`

[[ "$SUFFIX" == "" ]] && SUFFIX='png'

##########################################################################################

find * -maxdepth 0 -iname "${PREFIX} *\.${SUFFIX}" -print | while read line
do

		# Get creation time of the file in epoch seconds
	EPOCH_TIMESTAMP=$(zstat -L +ctime "$line")

		# convert to readable 24h time
	TIME_READABLE=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCH_TIMESTAMP"`

		# get short hostname
	SHOST=`hostname -s`

		# get file extension
	EXT="$line:e:l"

		# Put it all together
	FILENAME="${TIME_READABLE}--$SHOST:l.$EXT"

	mv -vf "$line" "$FILENAME"

	do_upload

done

##########################################################################################

exit
#
#EOF
