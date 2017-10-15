# yadshot

yadshot provides a GUI frontend for taking screenshots using maim/slop and uploads files and pastes to [teknik.io](https://teknik.io) using [teknik.sh](https://git.teknik.io/Teknikode/Tools/src/master/Upload/teknik.sh).  yadshot provides the following options:

yadshot : Opens a yad GUI with choices between uploading a file/image, a paste, or taking a screenshot.

yadshot -c : Uses yad to provide a GUI front end for maim/slop.  Images can be copied to clipboard, uploaded to teknik, or saved.

yadshot -p : Upload a paste from your clipboard to teknik.io.

yadshot -t : Opens a system tray app that gives options between uploading a file/image, paste, or taking a screenshot.

Dependencies: maim, slop, yad, xclip, curl, coreutils, imagemagick

![yadshot](/Screenshot.png)

![yadshot2](/Screenshot2.png)
