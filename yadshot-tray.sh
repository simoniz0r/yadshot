#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl

export RUNNING_DIR="$(dirname $(readlink -f $0))"

# create a FIFO file, used to manage the I/O redirection from shell
PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
mkfifo $PIPE

# attach a file descriptor to the file
exec 3<> $PIPE

# add handler to manage process shutdown
function on_exit() {
    echo "quit" >&3
    rm -f $PIPE
}
trap on_exit EXIT

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
    "$RUNNING_DIR"/yadshot-capture.sh
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
yad --notification                  \
    --listen                        \
    --image="gtk-dnd"              \
    --text="yadshot"   \
    --command="bash -c on_click"    \
    --item-separator=","            \
    --menu="Upload file/image,bash -c teknik_file,gtk-go-up|Upload paste,bash -c teknik_paste,gtk-copy|New screenshot,bash -c yadshot_capture,gtk-new|View upload list,bash -c upload_list,gtk-edit" <&3
    