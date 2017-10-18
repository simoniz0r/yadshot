#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for running maim/slop options
# License: GPL v2 Only
# Dependencies: coreutils, maim, slop, yad, xclip, curl

YADSHOT="$0"
RUNNING_DIR="$(dirname $(readlink -f $0))"
SS_NAME="yadshot$(date +'%m-%d-%y-%H%M%S').png"
SELECTION="TRUE"
DECORATIONS="TRUE"
CURSOR="FALSE"
SS_DELAY=0

if [ ! -d ~/.config/yadshot ]; then
    mkdir ~/.config/yadshot
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
    echo "CURSOR="\"$CURSOR\""" >> ~/.config/yadshot/yadshot.conf
fi

. ~/.config/yadshot/yadshot.conf

savesettingsfunc () {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
    echo "CURSOR="\"$CURSOR\""" >> ~/.config/yadshot/yadshot.conf
}

upload () {
    FAILED="0"
    "$RUNNING_DIR"/teknik.sh "$1" || FAILED="1"
}

capturefunc () {
    . ~/.config/yadshot/yadshot.conf
    if [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "TRUE" ] && [ "$CURSOR" = "FALSE" ]; then
        sleep 1
        maim -qluc 0,119,255,0.34 -d "$SS_DELAY" --format png  /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ] && [ "$CURSOR" = "FALSE" ]; then
        maim -qsluc 0,119,255,0.34 -d "$SS_DELAY" --format png /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ] && [ "$CURSOR" = "FALSE" ]; then
        maim -qslunc 0,119,255,0.34 -d "$SS_DELAY" --format png /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "FALSE" ] && [ "$CURSOR" = "FALSE" ]; then
        sleep 1
        maim -qlunc 0,119,255,0.34 -d "$SS_DELAY" --format png  /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "TRUE" ] && [ "$CURSOR" = "TRUE" ]; then
        sleep 1
        maim -qlc 0,119,255,0.34 -d "$SS_DELAY" --format png  /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ] && [ "$CURSOR" = "TRUE" ]; then
        maim -qslc 0,119,255,0.34 -d "$SS_DELAY" --format png /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ] && [ "$CURSOR" = "TRUE" ]; then
        maim -qslnc 0,119,255,0.34 -d "$SS_DELAY" --format png /tmp/"$SS_NAME"
    elif [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "FALSE" ] && [ "$CURSOR" = "TRUE" ]; then
        sleep 1
        maim -qlnc 0,119,255,0.34 -d "$SS_DELAY" --format png  /tmp/"$SS_NAME"
    fi
}

displayssfunc () {
    . ~/.config/yadshot/yadshot.conf
    WSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" " | awk '{print $1 * .75}')
    HSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" " | awk '{print $1 * .75}')
    WSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f2 -d" ")
    HSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f4 -d" ")
    if [ $WSCREEN_RES -le $WSIZE ] || [ $HSCREEN_RES -le $HSIZE ]; then
        mv /tmp/"$SS_NAME" /tmp/"$SS_NAME"_ORIGINAL
        convert -resize 50% /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
    fi
    OUTPUT="$(yad --center --form --image="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" --columns="4" --field="Capture selection":CHK "$SELECTION" --field="Capture decorations":CHK "$DECORATIONS" --field="Capture cursor":CHK "$CURSOR" --field="Delay before capture":NUM "$SS_DELAY!0..120" --button="Close"\!gtk-close:1 --button="Copy to clipboard"\!gtk-paste:2 --button="Upload to teknik"\!gtk-go-up:3 --button=gtk-save:4 --button="New Screenshot"\!gtk-new:0)"
    BUTTON_PRESSED="$?"
    if [ -f /tmp/"$SS_NAME"_ORIGINAL ]; then
        rm -f /tmp/"$SS_NAME"
        mv /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
    fi
    buttonpressedfunc
}

buttonpressedfunc () {
    case $BUTTON_PRESSED in
        1)
            rm -f /tmp/"$SS_NAME"
            exit 0
            ;;
        2)
            xclip -selection clipboard -t image/png -i < /tmp/"$SS_NAME"
            displayssfunc
            ;;
        3)
            cp /tmp/"$SS_NAME" $HOME/Pictures/"$SS_NAME"
            upload "$HOME/Pictures/"$SS_NAME""
            case $FAILED in
                0)
                    rm -f "$HOME/Pictures/"$SS_NAME""
                    displayssfunc
                    ;;
                1)
                    yad --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/"$SS_NAME""
                    displayssfunc
                    ;;
            esac
            ;;
        4)
            SAVE_DIR=$(yad --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            displayssfunc
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            SS_NAME="yadshot$(date +'%m-%d-%y-%l%M%p').png"
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            CURSOR="$(echo $OUTPUT | cut -f3 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f4 -d",")"
            savesettingsfunc
            exec "$YADSHOT"
            ;;
    esac
}

capturefunc
displayssfunc
buttonpressedfunc
