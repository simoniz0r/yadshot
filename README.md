# yadshot

![yadshot](/Screenshot.png)

yadshot uses [teknik.sh](https://git.teknik.io/Teknikode/Tools/src/master/Upload/teknik.sh) to upload files, images, and pastes to [teknik.io](https://teknik.io).  yadshot provides the vollowing options:

yadshot : Opens a yad GUI with choices between uploading a file/image, a paste, or taking a screenshot.

yadshot -c : Uses yad to provide a GUI front end for maim/slop.  Images can be copied to clipboard, uploaded to teknik, or saved.

yadshot -p : Upload a paste from your clipboard to teknik.io.  Requires xclip and curl.

yadshot -s : Upload a paste from your selection clipboard to teknik.io.  Requires xclip and curl.

yadshot -t : Opens a system tray app that gives options between uploading a file/image, paste, or taking a screenshot.

Dependencies: maim, slop, yad, xclip, curl, coreutils