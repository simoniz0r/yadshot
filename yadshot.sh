#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad --undecorated --center to provide a simple GUI for running maim/slop options
# License: GPL v2 Only
# Dependencies: coreutils, maim, slop, yad, xclip, curl

YADSHOT="$0"
default_client_id=c9a6efb3d7932fd
client_id="${IMGUR_CLIENT_ID:=$default_client_id}"
SS_NAME="yadshot$(date +'%m-%d-%y-%H%M%S').png"
SELECTION="TRUE"
DECORATIONS="TRUE"

if [ ! -d ~/.config/yadshot ]; then
    mkdir ~/.config/yadshot
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
fi

. ~/.config/yadshot/yadshot.conf

if [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "TRUE" ]; then
    MAIM="$(maim -l -c 0,119,255,0.34 -n --format png  /tmp/"$SS_NAME")"
elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "TRUE" ]; then
    MAIM="$(maim -l -c 0,119,255,0.34 -sn --format png /tmp/"$SS_NAME")"
elif [ "$SELECTION" = "TRUE" ] && [ "$DECORATIONS" = "FALSE" ]; then
    MAIM="$(maim -l -c 0,119,255,0.34 -s --format png /tmp/"$SS_NAME")"
elif [ "$SELECTION" = "FALSE" ] && [ "$DECORATIONS" = "FALSE" ]; then
    MAIM="$(maim -l -c 0,119,255,0.34 --format png  /tmp/"$SS_NAME")"
fi

savesettingsfunc () {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
}

upload () {
    curl -o /tmp/yadshot-upload-status -H "Authorization: Client-ID $client_id" -H "Expect: " -F "image=$1" https://api.imgur.com/3/image.xml
    CURL_STATUS="$?"
    # The "Expect: " header is to get around a problem when using this through
    # the Squid proxy. Not sure if it's a Squid bug or what.
}

capturefunc () {
    $MAIM
    WSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f2 -d" ")
    HSCREEN_RES=$(xrandr | grep 'current' | cut -f2 -d"," | sed 's:current ::g' | cut -f4 -d" ")
    WSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f4 -d" ")
    HSIZE=$(file /tmp/$SS_NAME | cut -f2 -d"," | cut -f4 -d" ")
    if [ $WSCREEN_RES -le $WSIZE ] || [ $HSCREEN_RES -le $HSIZE ]; then
        mv /tmp/"$SS_NAME" /tmp/"$SS_NAME"_ORIGINAL
        convert -resize 50% /tmp/"$SS_NAME"_ORIGINAL /tmp/"$SS_NAME"
    fi
    OUTPUT="$(yad --undecorated --center --form --image="/tmp/$SS_NAME" --image-on-top --buttons-layout="edge" --title="yadshot" --separator="," --borders="10" --columns="2" --field="Capture selection":CHK "$SELECTION" --field="Do not capture decorations":CHK "$DECORATIONS" --button="Close"\!gtk-close:1 --button="Copy to clipboard"\!gtk-paste:2 --button="Upload to imgur"\!gtk-go-up:3 --button=gtk-save:4 --button="New Screenshot"\!gtk-new:0)"
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
            capturefunc
            ;;
        3)
            cp /tmp/"$SS_NAME" $HOME/Pictures/"$SS_NAME"
            upload "@$HOME/Pictures/"$SS_NAME""
            case $CURL_STATUS in
                0)
                    url="$(cat /tmp/yadshot-upload-status | tr '<' '\n' | grep 'http://' | cut -f2 -d">")"
                    delete_hash="$(cat /tmp/yadshot-upload-status | tr '<' '\n' | grep 'deletehash' | cut -f2 -d">")"
                    url="$(echo $url | sed 's/^http:/https:/')"
                    echo "Screenshot uploaded to imgr!" > /tmp/yadshot-upload-output
                    echo "URL: $url" >> /tmp/yadshot-upload-output
                    echo "$url" | xclip -selection clipboard -i
                    echo "Delete link: https://imgur.com/delete/$delete_hash" >> /tmp/yadshot-upload-output
                    yad --undecorated --center --text-info --title="yadshot" --selectable-labels --show-uri --width=550 --height=150 --filename="/tmp/yadshot-upload-output"
                    rm -f "$HOME/Pictures/"$SS_NAME""
                    rm -f /tmp/yadshot-upload-output
                    rm -f /tmp/yadshot-upload-status
                    capturefunc
                    ;;
                *)
                    yad --undecorated --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/"$SS_NAME""
                    rm /tmp/yadshot-upload-output
                    rm /tmp/yadshot-upload-status
                    capturefunc
                    ;;
            esac
            ;;
        4)
            SAVE_DIR=$(yad --undecorated --center --file --save --confirm-overwrite --title="yadshot" --width=800 --height=600 --text="Save $SS_NAME as...")
            cp /tmp/"$SS_NAME" "$SAVE_DIR"
            capturefunc
            ;;
        0)
            rm -f /tmp/"$SS_NAME"
            SS_NAME="yadshot$(date +'%m-%d-%y-%l%M%p').png"
            SELECTION="$(echo $OUTPUT | cut -f1 -d",")"
            DECORATIONS="$(echo $OUTPUT | cut -f2 -d",")"
            savesettingsfunc
            exec "$YADSHOT"
            ;;
    esac
}

capturefunc
buttonpressedfunc
