ss2url -- Screen Shot To URL
============================

## ss2dropbox.sh

Shell script to upload screenshots to Dropbox and put share URL on pasteboard.

Requires [dropbox_uploader.sh][1]

## ss2url.sh

Shell script to upload screenshots to your own server via `scp`

## Growl

Both scripts use [Growl][2] and [growlnotify][3].

## History


### Dropbox’s built-in screensharing feature

Dropbox has a convenient feature to let you automatically upload screenshots to your Dropbox account. When you do this, the images will be automatically shared and the URLs added to the pasteboard.

I used it because it was convenient, although there were several parts of it that I didn't particularly like:

*	it didn't work if you changed the default screenshot name or the folder where screenshots were saved
*	you had no control over what directory they were uploaded to in your Dropbox
*	the filenames had spaces which meant that the URLs were ugly and cluttered with `%20`

### Dropping Dropbox

I’ve stopped using Dropbox on most of my Macs, opting instead for [BitTorrent Sync][4]. This means that the Dropbox app is not running on my Macs, and so my screenshots don’t get shared via Dropbox anymore.

I started out by simply wanting to replicate the Dropbox screenshot sharing feature, so I wrote [ss2dropbox.sh][5] which worked with the excellent [dropbox_uploader.sh][1].

Then I added a few features to make it work better:

1.	Screenshots are automatically renamed to show the date and time they were taken (no spaces in filenames)
2.	Screenshots can be in different formats (jpg vs png)
3.	If the directory for screenshots is changed, the script can still work
4.	Growl notifications can be clicked to open the public URL

Then I remembered that I was only using Dropbox for this because it was more convenient than doing it on my own. Except now it wasn’t.

So I wrote a _different_ script.

### Enter [ss2url.sh][6]

[ss2url.sh][6] has the same purpose as [ss2dropbox.sh][5] except that it doesn’t use Dropbox, it just uses `scp` to upload the images to my own server.

### Suggested Usage

#### Step 1: Change directory where screenshots are stored
Since screenshots are trashed after they are uploaded, I don’t have them saved to ~/Desktop/ (which is the default place for them). Instead I use /tmp/ as they are, in fact, temporary.

To make this change, I entered this line in Terminal:

	defaults write com.apple.screencapture location /tmp/

followed by

	killall SystemUIServer

#### Step 2: Tell `launchd` to look in the same directory

`launchd` is designed to run scripts whenever necessary. In this case, we can have it watch /tmp/ (or whatever directory we specified in step 1).

The script is smart enough to only look for files which match the screenshot preferences

To tell `launchd` to do this, you need a 'plist' file. I have included [com.tjluoma.ss2url.plist][7] as an example:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.tjluoma.ss2url</string>
		<key>Program</key>
		<string>/usr/local/bin/ss2url.sh</string>
		<key>RunAtLoad</key>
		<true/>
		<key>StandardErrorPath</key>
		<string>/tmp/com.tjluoma.ss2url.log</string>
		<key>StandardOutPath</key>
		<string>/tmp/com.tjluoma.ss2url.log</string>
		<key>WatchPaths</key>
		<array>
			<string>/tmp</string>
		</array>
	</dict>
	</plist>

If you did NOT change `defaults write com.apple.screencapture location` to `/tmp/` then you ***must*** change this line:

		<string>/tmp</string>

to the full path to the actual directory. By default, they will be saved to "$HOME/Desktop/" but you cannot use '$HOME' in a launchd plist, so you would want to include the explicit path like this:

		<string>/Users/jsmith/Desktop</string>

use your short username instead of `jsmith`.

Put the [com.tjluoma.ss2url.plist][7] file in ~/Library/LaunchAgents/ and enter this command in Terminal.app:

	launchctl load "$HOME/Library/LaunchAgents/com.tjluoma.ss2url.plist

You can confirm that it was properly loaded by using this command:

	launchctl list | fgrep ss2url

which should give you output something like this:

	-	0	com.tjluoma.ss2url


#### Step 3: Edit [ss2url.sh][6]

At the top of `ss2url.sh` are 3 variables that you ***must*** customize, or else the script will fail 100% of the time.

There are 4 subsequence variables that you _can_ customize.

Be sure to save the file and make it executable

	chmod 755 /usr/local/bin/ss2url.sh

Note: if you save [ss2url.sh][6] somewhere _other_ than `/usr/local/bin/ss2url.sh` be sure to change this line in the `plist`:

		<string>/usr/local/bin/ss2url.sh</string>



[1]:	https://github.com/andreafabrizi/Dropbox-Uploader/blob/master/dropbox_uploader.sh
[2]:	http://growl.info
[3]:	http://growl.info/downloads#generaldownloads
[4]:	http://sync-help.bittorrent.com
[5]:	https://github.com/tjluoma/ss2url/blob/master/ss2dropbox.sh
[6]:	https://github.com/tjluoma/ss2url/blob/master/ss2url.sh
[7]:	https://github.com/tjluoma/ss2url/blob/master/com.tjluoma.ss2url.plist


