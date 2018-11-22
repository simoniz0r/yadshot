#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl, grabc (optional - for use with color picker)

# export running directory variables for use later
export YADSHOT_PATH="$(readlink -f $0)"
export RUNNING_DIR="$(dirname $(readlink -f $0))"
if [ -f "/usr/share/icons/hicolor/scalable/apps/yadshot.svg" ]; then
    export ICON_PATH="/usr/share/icons/hicolor/scalable/apps/yadshot.svg"
else
    export ICON_PATH="gtk-fullscreen"
fi
# check for dependencies
if ! type curl >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)curl is not installed!$(tput sgr0)"
fi
if ! type import >/dev/null 2>&1 && [ ! -f "$RUNNING_DIR/ImageMagick" ] && ! type ffmpeg >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)imagemagick or ffmpeg not installed!$(tput sgr0)"
fi
if ! type yad >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)yad is not installed!$(tput sgr0)"
fi
if ! type xclip >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)xclip is not installed!$(tput sgr0)"
fi
if ! type slop >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)slop is not installed!$(tput sgr0)"
fi
if [ "$MISSING_DEPS" = "TRUE" ]; then
    echo "$(tput setaf 1)Missing one or more packages required to run; exiting...$(tput sgr0)"
    exit 1
fi
# set default variables
SS_NAME="yadshot-$(date +'%s').png"
SELECTION="TRUE"
DECORATIONS="TRUE"
SS_DELAY=0
if type ffmpeg >/dev/null 2>&1; then
    export YSHOT_IMAGE_PLUGIN="ffmpeg"
elif type import >/dev/null 2>&1 || [ -f "$RUNNING_DIR/ImageMagick" ]; then
    export YSHOT_IMAGE_PLUGIN="ImageMagick"
else
    export YSHOT_IMAGE_PLUGIN="Unknown"
fi
# create yadshot config dir
if [ ! -d "$HOME/.config/yadshot" ]; then
    mkdir -p ~/.config/yadshot
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
    echo "YSHOT_IMAGE_PLUGIN="\"$YSHOT_IMAGE_PLUGIN\""" >> ~/.config/yadshot/yadshot.conf
fi
# source yadshot config file
[ -f "$HOME/.config/yadshot/yadshot.conf" ] && . ~/.config/yadshot/yadshot.conf
if [ ! -d "$HOME/.config/yadshot/plugins" ]; then
    mkdir -p ~/.config/yadshot/plugins
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
    echo "YSHOT_IMAGE_PLUGIN="\"$YSHOT_IMAGE_PLUGIN\""" >> ~/.config/yadshot/yadshot.conf
fi

# add handler to manage process shutdown
function on_exit() {
    echo "quit" >&3
    rm -f $PIPE
    exit 0
}
export -f on_exit

# add handler for tray icon left click
function on_click() {
    "$YADSHOT_PATH"
    exit 0
}
export -f on_click
# function for uploading file from tray
function filebin_file() {
    "$YADSHOT_PATH" -f
    exit 0
}
export -f filebin_file
# function for uploading paste from tray
function filebin_paste() {
    "$YADSHOT_PATH" -p
    exit 0
}
export -f filebin_paste
# function for capturing screenshot from tray
function yadshot_capture() {
    "$YADSHOT_PATH" -s
    exit 0
}
export -f yadshot_capture
# function for launching color picker from tray
function yadshotcolor() {
    if type grabc > /dev/null 2>&1; then
        COLOR_SELECTION="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --color --init-color="$(grabc | head -n 1)" --mode=hex)"
    else
        COLOR_SELECTION="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --color --mode=hex)"
    fi
    case $? in
        0)
            echo -n "$COLOR_SELECTION" | xclip -i -selection clipboard
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
}
export -f yadshotcolor
# function to view upload list from tray
function upload_list() {
    LIST_ITEM="$("$RUNNING_DIR"/filebiner ls | tail -n +2 | yad --window-icon="$ICON_PATH" --borders=10 --center --list --height 600 --width 800 --title="yadshot" --text="\nDouble click an item to copy it to the clipboard." --dclick-action="bash -c 'echo -n %s | xclip -i -selection clipboard'" --separator="" --column="Uploads" --button="Delete Selected"\!gtk-delete:0 --button="Close"\!gtk-cancel:1)"
    case $? in
        1)
            sleep 0
            ;;
        0)
            local FILE_NAME="$(echo "$LIST_ITEM" | rev | cut -f2- -d'?' | cut -f1 -d'/' | rev)"
            filebiner -y rm -n "$FILE_NAME"
            case $? in
                1) yad --window-icon="$ICON_PATH" --borders=20 --center --info --title="yadshot" --button=gtk-ok --text="Failed to remove '$FILE_NAME' from Filebin!";;
                0) yad --window-icon="$ICON_PATH" --borders=20 --center --info --title="yadshot" --button=gtk-ok --text="'$FILE_NAME' has been removed from Filebin!";;
            esac
            "$YADSHOT_PATH" -l
            ;;
    esac
}
export -f upload_list

# create the notification icon
function yadshottray() {
    trap on_exit EXIT
    # create a FIFO file, used to manage the I/O redirection from shell
    PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
    mkfifo $PIPE
    # attach a file descriptor to the file
    exec 3<> $PIPE
    yad --window-icon="gtk-zoom-fit" --notification --listen --image="gtk-zoom-fit" --text="yadshot" --command="bash -c on_click" --item-separator="," \
    --menu="New Screenshot,bash -c yadshot_capture,gtk-new|Upload File,bash -c filebin_file,gtk-go-up|Upload Paste,bash -c filebin_paste,gtk-copy|Color Picker,bash -c yadshotcolor,gtk-color-picker|View Upload List,bash -c upload_list,gtk-edit|Quit,quit,gtk-cancel" <&3
}
export -f yadshottray
# save settings to yadshot config dir
function yadshotsavesettings() {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
    echo "YSHOT_IMAGE_PLUGIN="\"$YSHOT_IMAGE_PLUGIN\""" >> ~/.config/yadshot/yadshot.conf
}
export -f yadshotsavesettings
# change yadshot's settings
function yadshotsettings() {
    . ~/.config/yadshot/yadshot.conf
    if [ $(dir -C -w 1 $HOME/.config/yadshot/plugins | wc -l) -gt 0 ]; then
        YSHOT_PLUGIN_LIST="$(dir -C -w 1 $HOME/.config/yadshot/plugins | tr '\n' ',' | rev | cut -f2- -d',' | rev)"
    fi
    if type ffmpeg >/dev/null 2>&1; then
        YSHOT_PLUGIN_LIST="ffmpeg,$YSHOT_PLUGIN_LIST"
    fi
    if type import >/dev/null 2>&1 || [ -f "$RUNNING_DIR/ImageMagick" ]; then
        YSHOT_PLUGIN_LIST="ImageMagick,$YSHOT_PLUGIN_LIST"
    fi
    YSHOT_PLUGIN_LIST="$(echo $YSHOT_PLUGIN_LIST | tr ',' '\n' | grep -vw "$YSHOT_IMAGE_PLUGIN" | sed '/^$/d' | tr '\n' ',')"
    YSHOT_PLUGIN_LIST="$(echo $YSHOT_IMAGE_PLUGIN,$YSHOT_PLUGIN_LIST | rev | cut -f2- -d',' | rev)"
    OUTPUT="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=200 --columns=1 --form --no-escape --item-separator="," --separator="," --borders="10" \
    --field="Capture selection":CHK "$SELECTION" --field="Capture decorations":CHK "$DECORATIONS" --field="Delay before capture":NUM "$SS_DELAY!0..120" \
    --field="Image capture plugin":CB "$YSHOT_PLUGIN_LIST" --button="gtk-ok")"
    SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
    DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
    SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
    YSHOT_IMAGE_PLUGIN="$(echo $OUTPUT | cut -f4 -d",")"
    yadshotsavesettings
}
export -f yadshotsettings
# upload screenshots and files to Filebin.net; set FAILED=1 if upload fails
function yadshotupload() {
    "$RUNNING_DIR"/filebiner up -f "$1"
    FILE_URL="$(xclip -o -selection clipboard)"
    echo "$FILE_URL"
    if [[ -z "$FILE_URL" ]]; then
        echo 'error uploading file!\n'
        FAILED=1
        yad --window-icon="$ICON_PATH" --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/$SS_NAME"
    else
        FAILED=0
        rm -f "$HOME/Pictures/$SS_NAME"
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=20 --info --selectable-labels --title="yadshot" --button="Back"\!gtk-ok:0 --button="Close"\!gtk-cancel:1 --text="$FILE_URL"
        case $? in
            1)
                rm -f /tmp/"$SS_NAME"
                exit 0
                ;;
        esac
    fi
}
# detect which image capture plugin to use
function yadshotcaptureselect() {
    case "$YSHOT_IMAGE_PLUGIN" in
        ImageMagick)
            yadshotcapture
            ;;
        ffmpeg)
            yadshotcaptureffmpeg
            ;;
        *)
            if [ -f "$HOME/.config/yadshot/plugins/$YSHOT_IMAGE_PLUGIN" ]; then
                source ~/.config/yadshot/plugins/"$YSHOT_IMAGE_PLUGIN"
                yadshotcaptureplugin
            else
                yadshotcapture
            fi
            ;;
    esac
}
# capture screenshot using slop and imagemagick
function yadshotcapture() {
    . ~/.config/yadshot/yadshot.conf
    if [ "$SELECTION" = "FALSE" ]; then
        if [ $SS_DELAY -eq 0 ]; then
            SS_DELAY=0.5
        fi
        sleep "$SS_DELAY"
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick import -window root /tmp/"$SS_NAME"
        else
            import -window root /tmp/"$SS_NAME"
        fi
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ]; then
        read -r G < <(slop --nokeyboard -c 0,119,255,0.34 -f "%g")
        sleep "$SS_DELAY"
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick import -window root -crop $G /tmp/"$SS_NAME"
        else
            import -window root -crop $G /tmp/"$SS_NAME"
        fi
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ]; then
        read -r G < <(slop --nokeyboard -nc 0,119,255,0.34 -f "%g")
        sleep "$SS_DELAY"
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick import -window root -crop $G /tmp/"$SS_NAME"
        else
            import -window root -crop $G /tmp/"$SS_NAME"
        fi
    fi
}
# capture screenshot using slop and ffmpeg
function yadshotcaptureffmpeg() {
    . ~/.config/yadshot/yadshot.conf
    if [ "$SELECTION" = "FALSE" ]; then
        if [ $SS_DELAY -eq 0 ]; then
            SS_DELAY=0.5
        fi
        sleep "$SS_DELAY"
        W=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" ")
        H=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" ")
        ffmpeg -f x11grab -s "$W"x"$H" -i :0.0 -vframes 1 /tmp/"$SS_NAME" > /dev/null 2>&1
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ]; then
        MAXW=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" ")
        MAXH=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" ")
        read -r X Y W H G ID < <(slop --nokeyboard -c 0,119,255,0.34 -f "%x %y %w %h %g %i")
        [ $W -eq 1921 ] && W=1920
        [ $W -gt $MAXW ] && W=$MAXW
        [ $H -gt $MAXH ] && H=$MAXH
        [ $X -gt $MAXW ] && X=$MAXW
        [ $Y -gt $MAXH ] && Y=$MAXH
        sleep "$SS_DELAY"
        ffmpeg -f x11grab -s "$W"x"$H" -i :0.0+$X,$Y -vframes 1 /tmp/"$SS_NAME" # > /dev/null 2>&1
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ]; then
        MAXW=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" ")
        MAXH=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" ")
        read -r X Y W H G ID < <(slop --nokeyboard -nc 0,119,255,0.34 -f "%x %y %w %h %g %i")
        [ $W -gt $MAXW ] && W=$MAXW
        [ $H -gt $MAXH ] && H=$MAXH
        [ $X -gt $MAXW ] && X=$MAXW
        [ $Y -gt $MAXH ] && Y=$MAXH
        sleep "$SS_DELAY"
        ffmpeg -f x11grab -s "$W"x"$H" -i :0.0+$X,$Y -vframes 1 /tmp/"$SS_NAME" > /dev/null 2>&1
    fi
}
# display screenshot; resize it first if it's too large to be displayed on user's screen
function displayss() {
    . ~/.config/yadshot/yadshot.conf
    if [ ! -f "/tmp/$SS_NAME" ]; then
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to capture screenshot!"
        exit 1
    fi
    WSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" " | awk '{print $1 * .75}' | cut -f1 -d'.')
    HSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" " | awk '{print $1 * .75}' | cut -f1 -d'.')
    WSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f2 -d" " | cut -f1 -d'.')
    HSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f4 -d" " | cut -f1 -d'.')
    WSIZEYAD=$(($WSIZE+75))
    HSIZEYAD=$(($HSIZE+75))
    if [ $WSCREEN_RES -le $WSIZE ] || [ $HSCREEN_RES -le $HSIZE ]; then
        yad --window-icon="$ICON_PATH" --center --picture --size=fit --width=$WSCREEN_RES --height=$HSCREEN_RES --no-escape --filename="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" \
        --button="Close"\!gtk-cancel:1 --button="Main Menu"\!gtk-home:2 --button="Copy to Clipboard"\!gtk-paste:3 --button="Upload to Filebin"\!gtk-go-up:4 --button=gtk-save:5 --button="New Screenshot"\!gtk-new:0
    else
        yad --window-icon="$ICON_PATH" --center --picture --size=orig --width=$WSIZEYAD --height=$HSIZEYAD --no-escape --filename="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" \
        --button="Close"\!gtk-cancel:1 --button="Main Menu"\!gtk-home:2 --button="Copy to Clipboard"\!gtk-paste:3 --button="Upload to Filebin"\!gtk-go-up:4 --button=gtk-save:5 --button="New Screenshot"\!gtk-new:0
    fi
    BUTTON_PRESSED="$?"
    buttonpressed
}
# detect button pressed from displayss function and run relevant tasks
function buttonpressed() {
    case $BUTTON_PRESSED in
        1)
            rm -f /tmp/"$SS_NAME"
            exit 0
            ;;
        2)
            "$YADSHOT_PATH"
            ;;
        3)
            xclip -selection clipboard -t image/png -i < /tmp/"$SS_NAME"
            displayss
            ;;
        4)
            cp /tmp/"$SS_NAME" "$HOME"/Pictures/"$SS_NAME"
            yadshotupload "$HOME/Pictures/$SS_NAME"
            displayss
            ;;
        5)
            SAVE_DIR=$(yad --window-icon="$ICON_PATH" --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            displayss
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            yadshotsettings
            "$YADSHOT_PATH" -c
            ;;
    esac
}
# upload paste from clipboard to Filebin.net with optional syntax
function yadshotpaste() {
    echo -e "$(xclip -o -selection clipboard)" > /tmp/yadshotpaste.txt
    PASTE_CONTENT="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=600 --width=800 --text-info --filename="/tmp/yadshotpaste.txt" --editable --borders="10" --button="Cancel"\!gtk-cancel:1 --button="Ok"\!gtk-ok:0)"
    case $? in
        0)
            echo -e "$PASTE_CONTENT" > /tmp/yadshotpaste.txt
            ;;
        *)
            rm -f /tmp/yadshotpaste.txt
            exit 0
            ;;
    esac
    "$RUNNING_DIR"/filebiner up -f /tmp/yadshotpaste.txt
    PASTE_URL="$(xclip -o -selection clipboard)"
    rm -f /tmp/yadshotpaste.txt
    if [[ -z "$PASTE_URL" ]]; then
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=20 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
        exit 1
    else
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=20 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$PASTE_URL"
    fi
}
# get input from stdin and upload to Filebin.net
function yadshotpastepipe() {
    cat - > /tmp/yadshotpaste.txt
    "$RUNNING_DIR"/filebiner up -f /tmp/yadshotpaste.txt
    PASTE_URL="$(xclip -o -selection clipboard)"
    rm -f /tmp/yadshotpaste.txt
    if [[ ! "$PASTE_URL" =~ "http" ]]; then
        yad --center --height=150 --borders=20 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
        exit 1
    else
        yad --center --height=150 --borders=20 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$PASTE_URL"
    fi
}
# select a file to upload to Filebin.net
function yadshotfileselect() {
    FILE="$(yad --window-icon="$ICON_PATH" --file $PWD --center --title=yadshot --height 600 --width 800)"
    case $? in
        0)
            yadshotupload "$FILE"
            ;;
        *)
            exit 0
            ;;
    esac
}
# main yadshot window
function startfunc() {
    yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=200 --width=325 --form --no-escape --separator="" --button-layout="center" \
    --borders="20" --columns="1" --button="New Screenshot"\!gtk-add:0 --button="Close"\!gtk-cancel:1 \
    --field="Upload File!gtk-go-up":FBTN "$YADSHOT_PATH -f" --field="Upload Paste!gtk-copy":FBTN "$YADSHOT_PATH -p" \
    --field="Color Picker!gtk-color-picker":FBTN "$YADSHOT_PATH -C" --field="View Upload List!gtk-edit":FBTN "bash -c upload_list" \
    --field="Settings!gtk-preferences":FBTN "bash -c yadshotsettings" --field="Start Tray App!gtk-go-down":FBTN "bash -c yadshottray"
    case $? in
        0)
            yadshotsettings
            yadshotcaptureselect
            displayss
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
}
# help function
function yadshothelp() {
printf '%s\n' "yadshot v0.2.03
yadshot provides a GUI frontend for taking screenshots with 
ImageMagick/slop or ffmpeg/slop. yadshot can upload screenshots,
files, and pastes to Filebin.net.

Arguments:

--capture, -c       Capture a screenshot.  Screenshot will be shown after capture with
                    options to copy to clipboard, upload, or save.

--settings, -s      Show screenshot settings before capturing a screenshot.

--paste, -p         Upload a paste from your clipboard to Filebin.net.  Text may also be piped in from stdin.

--file, -f          Open the file chooser and upload a file to Filebin.net

--list, -l          List files uploaded to Filebin.net

--color, -C         Open color picker.  Color will be copied to clipboard if 'Ok' is pressed.

--tray, -t          Open a system tray app for quick access to yadshot.

If no argument is passed, yadshot's main menu will be shown.

"
}
# detect arguments
case $1 in
    -h|--help)
        yadshothelp
        exit 0
        ;;
    # use 'while IFS= read line; do' to check if data piped in from stdin otherwise display file chooser
    -p|--paste)
        shift
        for ARG in "$@"; do
            case "$ARG" in
                -s|--syntax)
                    shift
                    PASTE_SYNTAX=".$1"
                    shift
                    ;;
            esac
        done
        if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
            yadshotpastepipe
        else
            yadshotpaste
            exit 0
        fi
        ;;
    -f|--file)
        yadshotfileselect
        exit 0
        ;;
    -l|--list)
        upload_list
        exit 0
        ;;
    -s|--settings)
        yadshotsettings
        yadshotcaptureselect
        displayss
        exit 0
        ;;
    -c|--capture)
        yadshotcaptureselect
        displayss
        exit 0
        ;;
    -C|--color)
        yadshotcolor
        exit 0
        ;;
    -t|--tray)
        yadshottray &
        exit 0
        ;;
    *)
        startfunc
        ;;
esac
