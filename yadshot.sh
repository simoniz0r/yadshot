#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl

# export running directory variables for use later
export YADSHOT_PATH="$(readlink -f $0)"
export RUNNING_DIR="$(dirname $(readlink -f $0))"
if [ -f "/usr/share/icons/hicolor/64x64/apps/yadshot.png" ]; then
    export ICON_PATH="/usr/share/icons/hicolor/64x64/apps/yadshot.png"
else
    export ICON_PATH="gtk-fullscreen"
fi
# check for dependencies
if ! type curl >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)curl is not installed!$(tput sgr0)"
fi
if ! type import >/dev/null 2>&1 && [ ! -f "$RUNNING_DIR/ImageMagick" ]; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)imagemagick is not installed!$(tput sgr0)"
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
SS_NAME="yadshot$(date +'%m-%d-%y-%H%M%S').png"
SELECTION="TRUE"
DECORATIONS="TRUE"
SS_DELAY=0
# create yadshot config dir
if [ ! -d ~/.config/yadshot ]; then
    mkdir ~/.config/yadshot
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
fi
# source yadshot config file
[ -f "$HOME/.config/yadshot/yadshot.conf" ] && . ~/.config/yadshot/yadshot.conf

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
function teknik_file() {
    "$YADSHOT_PATH" -f
    exit 0
}
export -f teknik_file
# function for uploading paste from tray
function teknik_paste() {
    "$YADSHOT_PATH" -p
    exit 0
}
export -f teknik_paste
# function for capturing screenshot from tray
function yadshot_capture() {
    "$YADSHOT_PATH" -s
    exit 0
}
export -f yadshot_capture
# function for launching color picker from tray
function yadshotcolor() {
    COLOR_SELECTION="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --color)"
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
    LIST_ITEM="$(yad --window-icon="$ICON_PATH" --center --list --height 600 --width 800 --title="yadshot" --separator="" --column="Uploads" --button=gtk-close:2 --button="Delete list"\!gtk-delete:1 --button=gtk-copy:0 --rest="$HOME/.teknik")"
    case $? in
        2)
            sleep 0
            ;;
        1)
            yad --window-icon="$ICON_PATH" --center --info --title="yadshot" --button=gtk-ok --text="~/.teknik has been removed!"
            rm -f ~/.teknik
            ;;
        0)
            echo -n "$LIST_ITEM" | xclip -selection primary
            echo -n "$LIST_ITEM" | xclip -selection clipboard
            yad --window-icon="$ICON_PATH" --center --info --title="yadshot" --button=gtk-ok --text="$LIST_ITEM has been copied to clipboard."
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
    yad --window-icon="$ICON_PATH" --notification --listen --image="$ICON_PATH" --text="yadshot" --command="bash -c on_click" --item-separator="," \
    --menu="New Screenshot,bash -c yadshot_capture,gtk-new|Upload File,bash -c teknik_file,gtk-go-up|Upload Paste,bash -c teknik_paste,gtk-copy|Color Picker,bash -c yadshotcolor,gtk-color-picker|View Upload List,bash -c upload_list,gtk-edit" <&3
}
export -f yadshottray
# save settings to yadshot config dir
function yadshotsavesettings() {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
}
export -f yadshotsavesettings
# change yadshot's settings
function yadshotsettings() {
    . ~/.config/yadshot/yadshot.conf
    OUTPUT="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=200 --columns=1 --form --no-escape --separator="," --borders="10" \
    --field="Capture selection":CHK "$SELECTION" --field="Capture decorations":CHK "$DECORATIONS" \
    --field="Delay before capture":NUM "$SS_DELAY!0..120" --button="gtk-ok")"
    SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
    DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
    SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
    yadshotsavesettings
}
export -f yadshotsettings
# upload screenshots and files to teknik.io; set FAILED=1 if upload fails
function yadshotupload() {
    # if file is png, set type
    if [[ "$1" =~ ".png" ]]; then
        FILE_URL="$(curl -s -F file="@$1;type=image/png" "https://api.teknik.io/v1/Upload")"
        echo "$FILE_URL"
        if [[ ! "$FILE_URL" =~ "http" ]]; then
            echo 'error uploading file!\n'
            FAILED=1
        else
            FAILED=0
            FILE_URL="$(echo $FILE_URL | cut -f6 -d'"')"
            echo -n "$FILE_URL" | xclip -selection primary
            echo -n "$FILE_URL" | xclip -selection clipboard
            echo "$FILE_URL" >> ~/.teknik
            yad --window-icon="$ICON_PATH" --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$FILE_URL"
        fi
    else
        FILE_URL=$(curl -s -F file="@$1" "https://api.teknik.io/v1/Upload")
        echo "$FILE_URL"
        if [[ ! "$FILE_URL" =~ "http" ]]; then
            echo 'error uploading file!\n'
            yad --window-icon="$ICON_PATH" --center --error --title="yadshot" --text="Failed to upload $1"
        else
            FILE_URL="$(echo $FILE_URL | cut -f6 -d'"')"
            echo -n "$FILE_URL" | xclip -selection primary
            echo -n "$FILE_URL" | xclip -selection clipboard
            echo "$FILE_URL" >> ~/.teknik
            yad --window-icon="$ICON_PATH" --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$FILE_URL"
        fi
    fi
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
            $RUNNING_DIR/ImageMagick import -window root /tmp/"$SS_NAME"
        else
            import -window root /tmp/"$SS_NAME"
        fi
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ]; then
        read -r G < <(slop --nokeyboard -lc 0,119,255,0.34 -f "%g")
        sleep "$SS_DELAY"
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick import -window root -crop $G /tmp/"$SS_NAME"
        else
            import -window root -crop $G /tmp/"$SS_NAME"
        fi
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ]; then
        read -r G < <(slop --nokeyboard -nlc 0,119,255,0.34 -f "%g")
        sleep "$SS_DELAY"
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick import -window root -crop $G /tmp/"$SS_NAME"
        else
            import -window root -crop $G /tmp/"$SS_NAME"
        fi
    fi
}
# display screenshot; resize it first if it's too large to be displayed on user's screen
function displayss() {
    . ~/.config/yadshot/yadshot.conf
    WSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" " | awk '{print $1 * .75}' | cut -f1 -d'.')
    HSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" " | awk '{print $1 * .75}' | cut -f1 -d'.')
    WSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f2 -d" " | cut -f1 -d'.')
    HSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f4 -d" " | cut -f1 -d'.')
    if [ $WSCREEN_RES -le $WSIZE ] || [ $HSCREEN_RES -le $HSIZE ]; then
        mv /tmp/"$SS_NAME" /tmp/"$SS_NAME"_ORIGINAL
        if [ -f "$RUNNING_DIR/ImageMagick" ]; then
            "$RUNNING_DIR"/ImageMagick convert -resize 50% /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
        else
            convert -resize 50% /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
        fi
    fi
    OUTPUT="$(yad --window-icon="$ICON_PATH" --center --form --always-print-result --no-escape --image="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" --columns="4" --field="Capture selection":CHK "$SELECTION" --field="Capture decorations":CHK "$DECORATIONS" --field="Delay before capture":NUM "$SS_DELAY!0..120" --field="!gtk-color-picker!Color Picker":FBTN "yad --window-icon="$ICON_PATH" --color --center --title=yadshot" --button="Close"\!gtk-close:1 --button="Main Menu"\!gtk-home:2 --button="Copy to Clipboard"\!gtk-paste:3 --button="Upload to Teknik"\!gtk-go-up:4 --button=gtk-save:5 --button="New Screenshot"\!gtk-new:0)"
    BUTTON_PRESSED="$?"
    if [ -f /tmp/"$SS_NAME"_ORIGINAL ]; then
        rm -f /tmp/"$SS_NAME"
        mv /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
    fi
    buttonpressed
}
# detect button pressed from displayss function and run relevant tasks
function buttonpressed() {
    case $BUTTON_PRESSED in
        1)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            rm -f /tmp/"$SS_NAME"
            exit 0
            ;;
        2)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            "$YADSHOT_PATH"
            ;;
        3)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            xclip -selection clipboard -t image/png -i < /tmp/"$SS_NAME"
            displayss
            ;;
        4)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            cp /tmp/"$SS_NAME" $HOME/Pictures/"$SS_NAME"
            yadshotupload "$HOME/Pictures/$SS_NAME"
            case $FAILED in
                0)
                    rm -f "$HOME/Pictures/$SS_NAME"
                    displayss
                    ;;
                1)
                    yad --window-icon="$ICON_PATH" --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/$SS_NAME"
                    displayss
                    ;;
            esac
            ;;
        5)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            SAVE_DIR=$(yad --window-icon="$ICON_PATH" --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            displayss
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            SS_NAME="yadshot$(date +'%m-%d-%y-%l%M%p').png"
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            yadshotsavesettings
            "$YADSHOT_PATH" -c
            ;;
    esac
}
# upload paste from clipboard to paste.rs with optional syntax
function yadshotpaste() {
    PASTE_CONTENT="$(yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=600 --width=800 --form --separator="" --borders="10" --button="Ok"\!gtk-ok --button="Cancel"\!gtk-cancel:1 \
    --field="Paste":TXT "$(xclip -o -selection clipboard)")"
    case $? in
        0)
            echo -e "$PASTE_CONTENT" > /tmp/yadshotpaste.txt
            ;;
        *)
            exit 0
            ;;
    esac
    PASTE_SYNTAX="$(yad --center --title="yadshot" --height=100 --width=300 --form --separator="" --borders="10" --button="Ok"\!gtk-ok \
    --field="Paste Syntax:":CE "Appfile!Berksfile!Brewfile!C!Cheffile!DOT!Deliverfile!Emakefile!Fastfile!GNUmakefile!Gemfile!Guardfile!M!Makefile!OCamlMakefile!PL!R!Rakefile!Rantfile!Rprofile!S!SConscript!SConstruct!Scanfile!Sconstruct!Snakefile!Snapfile!Thorfile!Vagrantfile!adp!applescript!as!asa!asp!babel!bash!bat!bib!bsh!build!builder!c!c++!capfile!cc!cgi!cl!clj!cls!cmd!config.ru!cp!cpp!cpy!cs!css!css.erb!css.liquid!csx!cxx!d!ddl!di!diff!dml!dot!dpr!dtml!el!emakefile!erb!erbsql!erl!es6!fasl!fcgi!gemspec!go!gradle!groovy!gvy!gyp!gypi!h!h!h!h!h++!haml!hh!hpp!hrl!hs!htm!html!html.erb!hxx!inc!inl!ipp!irbrc!java!jbuilder!js!js.erb!json!jsp!jsx!l!lhs!lisp!lsp!ltx!lua!m!mak!make!makefile!markdn!markdown!matlab!md!mdown!mk!ml!mli!mll!mly!mm!mud!opml!p!pas!patch!php!php3!php4!php5!php7!phps!phpt!phtml!pl!pm!pod!podspec!prawn!properties!py!py3!pyi!pyw!r!rabl!rails!rake!rb!rbx!rd!re!rest!rhtml!rjs!rpy!rs!rss!rst!ruby.rail!rxml!s!sass!sbt!scala!scm!sconstruct!sh!shtml!simplecov!sql!sql.erb!ss!sty!svg!swift!t!tcl!tex!textile!thor!tld!tmpl!tpl!ts!tsx!txt!wscript!xhtml!xml!xsd!xslt!yaml!yaws!yml!zsh")"
    [ ! -z "$PASTE_SYNTAX" ] && PASTE_SYNTAX=".$PASTE_SYNTAX"
    PASTE_URL="$(curl -s --data-binary @/tmp/yadshotpaste.txt https://paste.rs/ | head -n 1)$PASTE_SYNTAX"
    rm -f /tmp/yadshotpaste.txt
    if [[ ! "$PASTE_URL" =~ "http" ]]; then
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
        exit 1
    else
        echo -n "$PASTE_URL" | xclip -i -selection primary
        echo -n "$PASTE_URL" | xclip -i -selection clipboard
        echo "$PASTE_URL" >> ~/.teknik
        yad --window-icon="$ICON_PATH" --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$PASTE_URL"
    fi
}
# main yadshot window with screenshot options and dropdown menu
function startfunc() {
    yad --window-icon="$ICON_PATH" --center --title="yadshot" --height=200 --width=325 --form --no-escape --separator="" --button-layout="center" \
    --borders="20" --columns="1" --button="New Screenshot"\!gtk-add:0 --button="Close"\!gtk-cancel:1 \
    --field="Upload File!gtk-go-up":FBTN "$YADSHOT_PATH -f" --field="Upload Paste!gtk-copy":FBTN "$YADSHOT_PATH -p" \
    --field="Color Picker!gtk-color-picker":FBTN "$YADSHOT_PATH -C" --field="View Upload List!gtk-edit":FBTN "bash -c upload_list" \
    --field="Settings!gtk-preferences":FBTN "bash -c yadshotsettings" --field="Start Tray App!gtk-go-down":FBTN "bash -c yadshottray"
    case $? in
        0)
            yadshotsettings
            yadshotcapture
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
printf '%s\n' "yadshot v0.1.99.1
yadshot provides a GUI frontend for taking screenshots with ImageMagick/slop.
yadshot can upload screenshots and files to teknik.io, and it can also upload
pastes to paste.rs

Arguments:

--capture, -c       Capture a screenshot.  Screenshot will be shown after capture with
                    options to copy to clipboard, upload, or save.

--settings, -s      Show screenshot settings before capturing a screenshot.

--paste, -p         Upload a paste from your clipboard to paste.rs.  Text may also be piped in from stdin.
                    Syntax may be specified with '--syntax' or '-s'. Ex:
                    'cat ./somefile.sh | yadshot -p -s sh'

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
            while IFS= read line; do
                echo -e "$line"
            done > /tmp/yadshotpaste.txt
            [ -z "$PASTE_SYNTAX" ] && PASTE_SYNTAX=""
            PASTE_URL="$(curl -s --data-binary @/tmp/yadshotpaste.txt https://paste.rs/ | head -n 1)$PASTE_SYNTAX"
            rm -f /tmp/yadshotpaste.txt
            if [[ ! "$PASTE_URL" =~ "http" ]]; then
                yad --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
                exit 1
            else
                echo -n "$PASTE_URL" | xclip -i -selection primary
                echo -n "$PASTE_URL" | xclip -i -selection clipboard
                echo "$PASTE_URL"
                echo "$PASTE_URL" >> ~/.teknik
                yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="$PASTE_URL"
            fi
        else
            yadshotpaste
            exit 0
        fi
        ;;
    -f|--file)
        FILE="$(yad --window-icon="$ICON_PATH" --file $PWD --center --title=yadshot --height 600 --width 800)"
        case $? in
            0)
                yadshotupload "$FILE"
                ;;
            *)
                exit 0
                ;;
        esac
        ;;
    -s|--settings)
        yadshotsettings
        yadshotcapture
        displayss
        exit 0
        ;;
    -c|--capture)
        yadshotcapture
        displayss
        exit 0
        ;;
    -C|--color)
        yadshotcolor
        exit 0
        ;;
    -t|--tray)
        bash -c 'yadshottray'
        ;;
    *)
        startfunc
        ;;
esac
