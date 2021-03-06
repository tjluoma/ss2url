#!/bin/zsh -f
# Purpose: publish images to images.luo.ma
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-12-10

# You MUST set the first 3 variables, otherwise there's no hope of this working.

	# This is the Remote HOSTname of the server where you will be scp'ing to
## MUST SET ##
RHOST='mini.luo.ma'

	# This is the folder on the $RHOST
	# Note that the path should be relative to your $HOME
## MUST SET ##
RDIR='Dropbox/images.luo.ma/ss'

	# What is the public URL for the RDIR folder?
## MUST SET ##
URL_ROOT='http://images.luo.ma/ss'


##########################################################################################
##########################################################################################
#
# You do not _need_ to change any of these 4 variables, but you might _want_ to

	# Which app should growlnotify use for the icon when displaying alerts
	# 	I still use and like the original Skitch, so I use some of its sounds
	# 	and its app icon. If you want, you can download it from here:
	# 		http://evernote.com/download/get.php?file=SkitchMac_v1
GROWL_APP='Skitch'

	# What sound should be played when the scp starts?
	# This can be any sound file on your Mac (as long as it can be played with `afplay`)
	# If it doesn't exist it will be quietly ignored
START_SND='/Applications/Skitch.app/Contents/Resources/PTW_commence.m4a'

	# What sound should be played if the scp succeeds?
	# This can be any sound file on your Mac (as long as it can be played with `afplay`)
	# If it doesn't exist it will be quietly ignored
SUCCESS_SND='/Applications/Skitch.app/Contents/Resources/PTW_complete.m4a'

	# What sound should be played if the scp fails?
	# This can be any sound file on your Mac (as long as it can be played with `afplay`)
	# If it doesn't exist it will be quietly ignored
FAIL_SND='/System/Library/Sounds/Sosumi.aiff'


##########################################################################################
##########################################################################################
##########################################################################################
#
#
# You should not change anything below here unless you really know what you are doing.
# But you are welcome to look through. There are lots of comments to help you follow my
# thought patterns.

zmodload zsh/stat
zmodload zsh/datetime

NAME="$0:t:r"

	# Check to see if the user has changed the default name which is prefixed to screenshots
PREFIX=`defaults read com.apple.screencapture name 2>/dev/null`

		# If no, use the default
	[[ "$PREFIX" == "" ]] && PREFIX='Screen Shot'

	# Has the user changed the KIND of image which will be used for screenshots?
	# Generally this might be set to JPG instead of PNG
SUFFIX=`defaults read com.apple.screencapture type 2>/dev/null`

		# if no, use the default
	[[ "$SUFFIX" == "" ]] && SUFFIX='png'

##########################################################################################

	# if the file needs to be renamed, this is the function which will do it
function rename_image {

		# Get the file extension
	EXT="$i:e:l"

		# get the ctime (creation time) of the file
	EPOCH_TIMESTAMP=$(zstat -L +ctime "$i")

		# reformat the creation time into something more readable
	TIME_READABLE=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCH_TIMESTAMP"`

		# put the new filename together
	NEW_NAME="$i:h/$TIME_READABLE.$EXT"

		# rename the file
	mv -vn "$i" "$NEW_NAME"

		# update the '$i' variable to refer to the new name
	i="$NEW_NAME"

}

##########################################################################################
##
## CASE 1 - NO ARGS = the script has been called with no arguments.
##				So we assume we need to check the default folder for screenshots
##				and process any that are found there

if [ "$#" = "0" ]
then
		# If no arguments are given, then we assume we want to process screenshots
		# and that we need to look for them in a specific directory
	   DIR=`defaults read com.apple.screencapture location 2>/dev/null`

		# If we did not get values for those, use the defaults
	[[ "$DIR" == "" ]]    && DIR="$HOME/Desktop"

		# chdir to the directory where screenshots go
	cd "$DIR"

		# find any files matching the screenshot filename and run this program on it
		## which will send us to the 'Case 2' below
		## Note the 'maxdepth 0' which prevents us from having to check every sub-folder
		## Also note that by limiting it to the LOGNAME of the user who called this script
		## we can use '/tmp/' directory without worrying too much about some jokester
		## putting properly named files in that directory to upload them to our server.
		## It's not a lot of security, but it's better than none.
	find * -maxdepth 0 -user "$LOGNAME" -iname "${PREFIX} *\.${SUFFIX}" -exec "$0" {} \; 2>/dev/null

		# We're done
	exit 0
fi

##########################################################################################
##########################################################################################
##
## CASE 2 - ARGS = the user has called the script with 1 or more arguments, presumably
##					these are image files that the user wants to upload
##

for i in "$@"
do
	if [ -e "$i" ]
	then

		case "$i:t" in
			"${PREFIX}"\ *)
					# If the filename starts with the generic screen shot prefix, rename the image
				rename_image
			;;

			Photo.png)
					# If the filename is the generic iOS screen shot filename, rename the image
				rename_image
			;;

		esac

			# This is the filename without the path
		SHORT="$i:t"

			# Compare $SHORT to what it would be if we replaced spaces with -
		TIDY=`echo "$SHORT" | tr -s ' ' '-'`

		if [ "$SHORT" = "$TIDY" ]
		then
				# If there is no difference then there are no spaces in the filename
				# so the Remote Filename can be the same as $SHORT
			RFILENAME="$SHORT"
		else
				# if there IS a difference, there are spaces in the local filename
				# which we will replace with '-' when we upload it to the server
				# Note that this is probably not a sufficient replacement for full
				# URL encoding, but it works well enough for me.
			RFILENAME="$TIDY"
		fi

			# play the "We're starting" sound
		afplay "$START_SND" 2>&1 >/dev/null &|

			# post a Growl notification that we're uploading the file
		growlnotify --sticky \
			--appIcon "$GROWL_APP" --identifier "$SHORT" \
			--message "$SHORT" --title "$NAME: Uploading"

			# upload the file
			# NOTE! No consideration is given to existing files. If a file with the
			# same name already exists, it will be overwritten. This is considered a feature.
		scp -E "${i}" "${RHOST}:${RDIR}/${RFILENAME}"

			# Did `scp` work?
		EXIT="$?"

		if [ "$EXIT" = "0" ]
		then
				# Yes, it worked

				# Play success sound
			afplay "$SUCCESS_SND" 2>&1 >/dev/null &|

				# Put together the resulting URL
			URL="${URL_ROOT}/${RFILENAME}"

				# Tell the user what the URL is, and open the URL if the Growl notification is clicked
			growlnotify \
			--url "$URL" --appIcon "Skitch" --identifier "$SHORT" \
			--message "$URL" --title "On Pasteboard:"

				# put the URL on the pasteboard
			echo -n "${URL_ROOT}/${SHORT}" | pbcopy

				# Move the file to the trash
			trash "$i" 2>/dev/null || mv -vf "$i" "$HOME/.Trash/"

		else
				# if we get here, scp failed

				# play 'failed' sound
			afplay "$FAIL_SND" 2>&1 >/dev/null &|

				# put a sticky notification that the upload failed
			growlnotify --sticky \
			--appIcon "Skitch" --identifier "$SHORT" \
			--message "$SHORT" --title "$NAME: FAILED"
		fi

	fi # if exists
done

exit 0
#
#EOF
