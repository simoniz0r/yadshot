#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl

export RUNNING_DIR="$(dirname $(readlink -f $0))"

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
if [ "$MISSING_DEPS" = "TRUE" ]; then
    echo "$(tput setaf 1)Missing one or more packages required to run; exiting...$(tput sgr0)"
    exit 1
fi

SS_NAME="yadshot$(date +'%m-%d-%y-%H%M%S').png"
SELECTION="TRUE"
DECORATIONS="TRUE"
SS_DELAY=0

if [ ! -d ~/.config/yadshot ]; then
    mkdir ~/.config/yadshot
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
fi

[ -f "$HOME/.config/yadshot/yadshot.conf" ] && . ~/.config/yadshot/yadshot.conf

# add handler to manage process shutdown
function on_exit() {
    echo "quit" >&3
    rm -f $PIPE
}
export -f on_exit

# add handler for tray icon left click
function on_click() {
    "$RUNNING_DIR"/yadshot.sh
}
export -f on_click

function teknik_file() {
    "$RUNNING_DIR"/yadshot.sh -f
}
export -f teknik_file

function teknik_paste() {
    "$RUNNING_DIR"/yadshot.sh -p
}
export -f teknik_paste

function yadshot_capture() {
    "$RUNNING_DIR"/yadshot.sh -c
}
export -f yadshot_capture

function upload_list() {
    LIST_ITEM="$(yad --center --list --height 600 --width 800 --title="yadshot" --separator="" --column="Uploads" --button=gtk-close:2 --button="Delete list"\!gtk-delete:1 --button=gtk-copy:0 --rest="$HOME/.teknik")"
    case $? in
        2)
            sleep 0
            ;;
        1)
            yad --center --info --title="yadshot" --button=gtk-ok --text="~/.teknik has been removed!"
            rm -f ~/.teknik
            ;;
        0)
            echo -n "$LIST_ITEM" | xclip -selection primary
            echo -n "$LIST_ITEM" | xclip -selection clipboard
            yad --center --info --title="yadshot" --button=gtk-ok --text="$LIST_ITEM has been copied to clipboard."
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
    yad --notification --listen --image="gtk-dnd" --text="yadshot" --command="bash -c on_click" --item-separator="," \
    --menu="New Screenshot,bash -c yadshot_capture,gtk-new|Upload File,bash -c teknik_file,gtk-go-up|Upload Paste,bash -c teknik_paste,gtk-copy|View Upload List,bash -c upload_list,gtk-edit" <&3
}

function savesettings() {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
}

function yadshotupload() {
    FAILED="0"
    "$RUNNING_DIR"/teknik.sh "$1" || FAILED="1"
}

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
    OUTPUT="$(yad --center --form --always-print-result --no-escape --image="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" --columns="4" --field="Capture selection":CHK "$SELECTION" --field="Capture decorations":CHK "$DECORATIONS" --field="Delay before capture":NUM "$SS_DELAY!0..120" --button="Close"\!gtk-close:1 --button="Copy to clipboard"\!gtk-paste:2 --button="Upload to teknik"\!gtk-go-up:3 --button=gtk-save:4 --button="New Screenshot"\!gtk-new:0)"
    BUTTON_PRESSED="$?"
    if [ -f /tmp/"$SS_NAME"_ORIGINAL ]; then
        rm -f /tmp/"$SS_NAME"
        mv /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
    fi
    buttonpressed
}

function buttonpressed() {
    case $BUTTON_PRESSED in
        1)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettings
            rm -f /tmp/"$SS_NAME"
            exit 0
            ;;
        2)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettings
            xclip -selection clipboard -t image/png -i < /tmp/"$SS_NAME"
            displayss
            ;;
        3)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettings
            cp /tmp/"$SS_NAME" $HOME/Pictures/"$SS_NAME"
            yadshotupload "$HOME/Pictures/"$SS_NAME""
            case $FAILED in
                0)
                    rm -f "$HOME/Pictures/"$SS_NAME""
                    displayss
                    ;;
                1)
                    yad --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/"$SS_NAME""
                    displayss
                    ;;
            esac
            ;;
        4)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettings
            SAVE_DIR=$(yad --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            displayss
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            SS_NAME="yadshot$(date +'%m-%d-%y-%l%M%p').png"
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettings
            "$RUNNING_DIR"/yadshot.sh
            ;;
    esac
}

function startfunc() {
    OUTPUT="$(yad --center --title="yadshot" --height=200 --form --always-print-result --no-escape --text-align="center" \
    --separator="," --borders="10" --columns="2" --button="Ok"\!gtk-ok --button="Cancel"\!gtk-cancel:1 \
    --field="":LBL "" --field="":CB "New Screenshot!Upload File!Upload Paste!View Upload List" --field="":LBL "" --field="Capture selection":CHK "$SELECTION" \
    --field="Capture decorations":CHK "$DECORATIONS" --field="Delay before capture":NUM "$SS_DELAY!0..120")"
    case $? in
        0)
            SELECTION="$(echo $OUTPUT | cut -f4 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f5 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f6 -d",")"
            savesettings
            case $(echo $OUTPUT | cut -f2 -d',') in
                New*)
                    yadshotcapture
                    displayss
                    ;;
                *File*)
                    FILE="$(yad --file $PWD --center --title=yadshot --height 600 --width 800)"
                    case $? in
                        0)
                            "$RUNNING_DIR"/teknik.sh "$FILE"
                            ;;
                        *)
                            exit 0
                            ;;
                    esac
                    ;;
                *Paste*)
                    PASTE_INPUT="$(yad --form --title="yadshot" --center --height 600 --width 800 --field="":TXT "$(xclip -o -selection -clipboard)" --button=gtk-cancel:1 --button="Upload paste"\!gtk-copy:0)"
                    case $? in
                        0)
                            echo -e "$PASTE_INPUT" | xclip -i -selection -clipboard
                            "$RUNNING_DIR"/teknik.sh -p
                            ;;
                        *)
                            exit 0
                            ;;
                    esac
                    ;;
                View*)
                    LIST_ITEM="$(yad --center --list --height 600 --width 800 --title="yadshot" --separator="" --column="Uploads" --button=gtk-close:2 --button="Delete list"\!gtk-delete:1 --button=gtk-copy:0 --rest="$HOME/.teknik")"
                    case $? in
                        2)
                            sleep 0
                            ;;
                        1)
                            yad --center --info --title="yadshot" --button=gtk-ok --text="~/.teknik has been removed!"
                            rm -f ~/.teknik
                            ;;
                        0)
                            echo -n "$LIST_ITEM" | xclip -i -selection primary
                            echo -n "$LIST_ITEM" | xclip -i -selection clipboard
                            yad --center --info --title="yadshot" --button=gtk-ok --text="$LIST_ITEM has been copied to clipboard."
                            ;;
                    esac
                    ;;
            esac
            exit 0
            ;;
        1)
            SELECTION="$(echo $OUTPUT | cut -f4 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f5 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f6 -d",")"
            savesettings
            exit 0
            ;;
    esac
}

case $1 in
    -p*|--p*|-s*|--s*)
        if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
            while read -r line; do
                echo -e "$line"
            done | xclip -i -selection clipboard
            "$RUNNING_DIR"/teknik.sh -p
        else
            PASTE_INPUT="$(yad --form --title="yadshot" --center --height 600 --width 800 --field="":TXT "$(xclip -o -selection -clipboard)" --button=gtk-cancel:1 --button="Upload paste"\!gtk-copy:0)"
            case $? in
                0)
                    echo "$PASTE_INPUT" | xclip -i -selection -clipboard
                    "$RUNNING_DIR"/teknik.sh -p
                    ;;
                *)
                    exit 0
                    ;;
            esac
        fi
        ;;
    -f*|--f*)
        FILE="$(yad --file $PWD --center --title=yadshot --height 600 --width 800)"
        case $? in
            0)
                "$RUNNING_DIR"/teknik.sh "$FILE"
                ;;
            *)
                exit 0
                ;;
        esac
        ;;
    -c*|--c*)
        yadshotcapture
        displayss
        exit 0
        ;;
    -t*|--t*)
        yadshottray
        ;;
    *)
        startfunc
        ;;
esac
