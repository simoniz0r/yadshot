#!/bin/bash -x
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl

YADSHOT="$0"
RUNNING_DIR="$(dirname $(readlink -f $0))"
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

. ~/.config/yadshot/yadshot.conf

savesettingsfunc () {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
}

upload () {
    FAILED="0"
    "$RUNNING_DIR"/teknik.sh "$1" || FAILED="1"
}

capturefunc () {
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

displayssfunc () {
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
    buttonpressedfunc
}

buttonpressedfunc () {
    case $BUTTON_PRESSED in
        1)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettingsfunc
            rm -f /tmp/"$SS_NAME"
            exit 0
            ;;
        2)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettingsfunc
            xclip -selection clipboard -t image/png -i < /tmp/"$SS_NAME"
            displayssfunc
            ;;
        3)
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettingsfunc
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
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettingsfunc
            SAVE_DIR=$(yad --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            displayssfunc
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            SS_NAME="yadshot$(date +'%m-%d-%y-%l%M%p').png"
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            SS_DELAY="$(echo $OUTPUT | cut -f3 -d",")"
            savesettingsfunc
            exec "$YADSHOT"
            ;;
    esac
}

capturefunc
displayssfunc
