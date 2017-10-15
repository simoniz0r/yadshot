#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad --undecorated --center to provide a simple GUI for running maim/slop options
# License: GPL v2 Only
# Dependencies: coreutils, maim, slop, yad, xclip, curl

RUNNING_DIR="$(dirname $(readlink -f $0))"

if ! type curl >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)curl is not installed!$(tput sgr0)"
fi
if ! type maim >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)maim is not installed!$(tput sgr0)"
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

TEKNIK="$RUNNING_DIR/teknik.sh"
YADSHOT="$RUNNING_DIR/yadshot-capture.sh"
TRAY="$RUNNING_DIR/yadshot-tray.sh"

startfunc () {
    yad --center --title="yadshot" --text="Welcome to yadshot" --text-align="center" --height=100 --info --buttons-layout="edge" --button="Upload file/image"\!gtk-go-up:1 --button="Upload paste"\!gtk-copy:2 --button="New Screenshot"\!gtk-new:0 --button="View upload list"\!gtk-edit:4 --button=gtk-cancel:3
    case $? in
        1)
            FILE="$(yad --file --center --title=yadshot)"
            case $? in
                0)
                    $TEKNIK "$FILE"
                    ;;
                *)
                    exit 0
                    ;;
            esac
            ;;
        2)
            $TEKNIK -p
            ;;
        0)
            $YADSHOT
            ;;
        4)
            LIST_ITEM="$(yad --center --list --title="yadshot" --separator="" --column="Uploads" --button=gtk-close:2 --button="Delete list"\!gtk-delete:1 --button=gtk-copy:0 --rest="$HOME/.teknik")"
            case $? in
                2)
                    sleep 0
                    ;;
                1)
                    yad --center --info --title="yadshot" --button=gtk-ok --text="~/.teknik has been removed!"
                    rm -f ~/.teknik
                    ;;
                0)
                    echo "$LIST_ITEM" | xclip -selection primary
                    echo "$LIST_ITEM" | xclip -selection clipboard
                    yad --center --info --title="yadshot" --button=gtk-ok --text="$LIST_ITEM has been copied to clipboard."
                    ;;
            esac
            ;;
        3)
            exit 0
            ;;
    esac
}

case $@ in
    -p*|--p*)
        $TEKNIK -p
        ;;
    -s*|--s*)
        $TEKNIK -p
        ;;
    -f*|--f*)
        FILE="$(yad --file --center --title=yadshot)"
        case $? in
            0)
                $TEKNIK "$FILE"
                ;;
            *)
                exit 0
                ;;
        esac
        ;;
    -c*|--c*)
        $YADSHOT
        ;;
    -t*|--t*)
        $TRAY
        ;;
    *)
        startfunc
        ;;
esac
