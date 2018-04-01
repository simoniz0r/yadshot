# yadshot

yadshot uses ImageMagick/slop to take screenshots.  yadshot can upload screenshots and files to https://teknik.io, and it can also upload pastes to https://paste.rs

Arguments:

```
yadshot      Open yadshot's main menu.

yadshot -c   Capture a screenshot.  Screenshot will be shown after capture with
             options to copy to clipboard, upload, or save.

yadshot -p   Upload a paste from your clipboard to paste.rs.  Text may also be piped in from stdin.
             Syntax may be specified with '--syntax' or '-s'. Ex:
             'cat ./somefile.sh | yadshot -p -s sh'

yadshot -t   Open a system tray app for quick access to yadshot.
```

Dependencies: slop, imagemagick, yad, xclip, curl

Main Window:

![yadshot](/Screenshot.png)

Screenshot View and Tray:

![yadshot](/Screenshot2.png)

Upload Paste:

![yadshot](/Screenshot3.png)

View Upload List:

![yadshot](/Screenshot4.png)
