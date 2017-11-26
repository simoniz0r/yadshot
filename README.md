# yadshot

yadshot provides a GUI frontend for taking screenshots using maim/slop and uploads files and pastes to [teknik.io](https://teknik.io) using [teknik.sh](https://git.teknik.io/Teknikode/Tools/src/master/Upload/teknik.sh).  yadshot provides the following options:

yadshot : Opens a yad dialog with choices between uploading a file/image, a paste, or taking a screenshot.

yadshot -c : Captures a screenshot using slop and imagemagick's import.  Uses yad to display the screenshot and give options to copy, upload, or save the screenshot.

yadshot -p : Upload a paste from your clipboard to teknik.io.

yadshot -t : Opens a system tray app that gives options between uploading a file/image, paste, or taking a screenshot.

Dependencies: slop, imagemagick, yad, xclip, curl

![yadshot](/Screenshot.png)
