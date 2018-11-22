# yadshot

yadshot uses ImageMagick or ffmpeg and slop to take screenshots.  yadshot can upload screenshots, files, and pastes to https://Filebin.net.

Arguments:

```

--capture, -c       Capture a screenshot.  Screenshot will be shown after capture with
                    options to copy to clipboard, upload, or save.

--settings, -s      Show screenshot settings before capturing a screenshot.

--paste, -p         Upload a paste from your clipboard to Filebin.net.  Text may also be piped in from stdin.

--file, -f          Open file chooser to upload a file to Filebin.net

--list, -l          List files uploaded to Filebin.net

--color, -C         Open color picker.  Color will be copied to clipboard if 'Ok' is pressed.

--tray, -t          Open a system tray app for quick access to yadshot.

If no argument is passed, yadshot's main menu will be shown.

```

Dependencies: slop, imagemagick or ffmpeg, yad, xclip, curl, grabc (optional - for use with color picker)

Main Window:

![yadshot](/Screenshot.png)

Screenshot View and Tray:

![yadshot](/Screenshot2.png)

Upload Paste:

![yadshot](/Screenshot3.png)

View Upload List:

![yadshot](/Screenshot4.png)

<div>yadshot icon made by <a href="https://www.flaticon.com/authors/pixel-buddha" title="Pixel Buddha">Pixel Buddha</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
