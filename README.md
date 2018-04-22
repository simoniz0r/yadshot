# yadshot

yadshot uses ImageMagick or ffmpeg and slop to take screenshots.  yadshot can upload screenshots and files to https://teknik.io, and it can also upload pastes to https://paste.rs

Arguments:

```

--capture, -c       Capture a screenshot.  Screenshot will be shown after capture with
                    options to copy to clipboard, upload, or save.

--settings, -s      Show screenshot settings before capturing a screenshot.

--paste, -p         Upload a paste from your clipboard to paste.rs.  Text may also be piped in from stdin.
                    Syntax may be specified with '--syntax' or '-s'. Ex:
                    'cat ./somefile.sh | yadshot -p -s sh'

--file, -f          Open file chooser to upload a file to teknik.io

--color, -C         Open color picker.  Color will be copied to clipboard if 'Ok' is pressed.

--tray, -t          Open a system tray app for quick access to yadshot.

If no argument is passed, yadshot's main menu will be shown.

```

Dependencies: slop, imagemagick or ffmpeg, yad, xclip, curl

Main Window:

![yadshot](/Screenshot.png)

Screenshot View and Tray:

![yadshot](/Screenshot2.png)

Upload Paste:

![yadshot](/Screenshot3.png)

View Upload List:

![yadshot](/Screenshot4.png)

<div>yadshot icon made by <a href="https://www.flaticon.com/authors/pixel-buddha" title="Pixel Buddha">Pixel Buddha</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
