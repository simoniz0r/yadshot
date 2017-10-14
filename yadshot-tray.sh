#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad --undecorated --center to provide a simple GUI for running maim/slop options
# License: GPL v2 Only
# Dependencies: coreutils, maim, slop, yad, xclip, curl

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
    "$RUNNING_DIR"/teknik.sh -p
}
export -f teknik_paste

function yadshot_capture() {
    "$RUNNING_DIR"/yadshot-capture.sh
}
export -f yadshot_capture

# create the notification icon
yad --notification                  \
    --listen                        \
    --image="gtk-dnd"              \
    --text="yadshot"   \
    --command="bash -c on_click"    \
    --item-separator=","            \
    --menu="Upload file/image,bash -c teknik_file,gtk-go-up|Upload paste,bash -c teknik_paste,gtk-copy|New screenshot,bash -c yadshot_capture,gtk-new" <&3
    