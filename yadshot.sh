#!/bin/bash
# Title: yadshot
# Author: simoniz0r
# Description: Uses yad to provide a simple GUI for using slop to capture screenshots using Imagemagick's import
# License: GPL v2 Only
# Dependencies: coreutils, slop, imagemagick, yad, xclip, curl

export YADSHOT_PATH="$(readlink -f $0)"
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
if ! type slop >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "$(tput setaf 1)slop is not installed!$(tput sgr0)"
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
    "$YADSHOT_PATH"
}
export -f on_click

function teknik_file() {
    "$YADSHOT_PATH" -f
}
export -f teknik_file

function teknik_paste() {
    "$YADSHOT_PATH" -p
}
export -f teknik_paste

function yadshot_capture() {
    "$YADSHOT_PATH" -c
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
export -f yadshottray

function savesettings() {
    echo "SELECTION="\"$SELECTION\""" > ~/.config/yadshot/yadshot.conf
    echo "DECORATIONS="\"$DECORATIONS\""" >> ~/.config/yadshot/yadshot.conf
    echo "SS_DELAY="\"$SS_DELAY\""" >> ~/.config/yadshot/yadshot.conf
}

function yadshotupload() {
    if [[ "$1" =~ ".png" ]]; then
        FILE_URL="$(curl -s -F file="@$1;type=image/png" "https://api.teknik.io/v1/Upload")"
        echo "$FILE_URL"
        if [[ ! "$FILE_URL" =~ "http" ]]; then
            printf  'error uploading file!\n'
            FAILED=1
        else
            FAILED=0
            FILE_URL="$(echo $FILE_URL | cut -f6 -d'"')"
            echo "$FILE_URL" | xclip -selection primary
            echo "$FILE_URL" | xclip -selection clipboard
            echo "$FILE_URL" >> ~/.teknik
            yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="Picture uploaded to $FILE_URL"
        fi
    else
        FILE_URL=$(curl -s -F file="@$1" "https://api.teknik.io/v1/Upload")
        echo "$FILE_URL"
        if [[ ! "$FILE_URL" =~ "http" ]]; then
            printf	'error uploading file!\n'
            yad --center --error --title="yadshot" --text="Failed to upload $1"
        else
            FILE_URL="$(echo $FILE_URL | cut -f6 -d'"')"
            echo "$FILE_URL" | xclip -selection primary
            echo "$FILE_URL" | xclip -selection clipboard
            echo "$FILE_URL" >> ~/.teknik
            yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="File uploaded to $FILE_URL"
        fi
    fi
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
            yadshotupload "$HOME/Pictures/$SS_NAME"
            case $FAILED in
                0)
                    rm -f "$HOME/Pictures/$SS_NAME"
                    displayss
                    ;;
                1)
                    yad --center --error --title="yadshot" --text="$SS_NAME upload failed; screenshot stored in $HOME/Pictures/$SS_NAME"
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
            "$YADSHOT_PATH" -c
            ;;
    esac
}

function yadshotpaste() {
    echo "$(xclip -o -selection clipboard)" > /tmp/yadshotpaste.txt
    PASTE_SETTINGS="$(yad --center --title="yadshot" --height=100 --width=300 --form --separator="," --borders="10" --button="Ok"\!gtk-ok --button="Cancel"\!gtk-cancel:1 \
    --field="Paste Syntax:":CE "Appfile!Berksfile!Brewfile!C!Cheffile!DOT!Deliverfile!Emakefile!Fastfile!GNUmakefile!Gemfile!Guardfile!M!Makefile!OCamlMakefile!PL!R!Rakefile!Rantfile!Rprofile!S!SConscript!SConstruct!Scanfile!Sconstruct!Snakefile!Snapfile!Thorfile!Vagrantfile!adp!applescript!as!asa!asp!babel!bash!bat!bib!bsh!build!builder!c!c++!capfile!cc!cgi!cl!clj!cls!cmd!config.ru!cp!cpp!cpy!cs!css!css.erb!css.liquid!csx!cxx!d!ddl!di!diff!dml!dot!dpr!dtml!el!emakefile!erb!erbsql!erl!es6!fasl!fcgi!gemspec!go!gradle!groovy!gvy!gyp!gypi!h!h!h!h!h++!haml!hh!hpp!hrl!hs!htm!html!html.erb!hxx!inc!inl!ipp!irbrc!java!jbuilder!js!js.erb!json!jsp!jsx!l!lhs!lisp!lsp!ltx!lua!m!mak!make!makefile!markdn!markdown!matlab!md!mdown!mk!ml!mli!mll!mly!mm!mud!opml!p!pas!patch!php!php3!php4!php5!php7!phps!phpt!phtml!pl!pm!pod!podspec!prawn!properties!py!py3!pyi!pyw!r!rabl!rails!rake!rb!rbx!rd!re!rest!rhtml!rjs!rpy!rs!rss!rst!ruby.rail!rxml!s!sass!sbt!scala!scm!sconstruct!sh!shtml!simplecov!sql!sql.erb!ss!sty!svg!swift!t!tcl!tex!textile!thor!tld!tmpl!tpl!ts!tsx!txt!wscript!xhtml!xml!xsd!xslt!yaml!yaws!yml!zsh")"
    case $? in
        0)
            sleep 0
            ;;
        *)
            exit 0
            ;;
    esac
    PASTE_SYNTAX="$(echo -e $PASTE_SETTINGS | cut -f1 -d',')"
    PASTE_URL="$(curl -s --data-binary @/tmp/yadshotpaste.txt https://paste.rs/ | head -n 1).$PASTE_SYNTAX"
    rm -f /tmp/yadshotpaste.txt
    if [[ ! "$PASTE_URL" =~ "http" ]]; then
        yad --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
        exit 1
    else
        echo -n "$PASTE_URL" | xclip -i -selection primary
        echo -n "$PASTE_URL" | xclip -i -selection clipboard
        echo "$PASTE_URL" >> ~/.teknik
        yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="Paste uploaded to $PASTE_URL"
    fi
}

function startfunc() {
    OUTPUT="$(yad --center --title="yadshot" --height=200 --form --always-print-result --no-escape \
    --separator="," --borders="10" --columns="2" --button="Ok"\!gtk-ok --button="Cancel"\!gtk-cancel:1 \
    --field=" ":LBL " " --field="":CB "New Screenshot!Upload File!Upload Paste!View Upload List" --field=" ":LBL " " --field="Capture selection":CHK "$SELECTION" \
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
                            yadshotupload "$FILE"
                            ;;
                        *)
                            exit 0
                            ;;
                    esac
                    ;;
                *Paste*)
                    yadshotpaste
                    exit 0
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

function yadshothelp() {
printf '%s\n' "yadshot v0.1.95
yadshot provides a GUI frontend for taking screenshots with ImageMagick/slop.
yadshot can upload screenshots and files to teknik.io, and it can also upload
pastes to paste.rs

Arguments:

yadshot      Open yadshot's main menu.

yadshot -c   Capture a screenshot.  Screenshot will be shown after capture with
             options to copy to clipboard, upload, or save.

yadshot -p   Upload a paste from your clipboard to paste.rs.  Text may also be piped in from stdin.
             Syntax may be specified with '--syntax' or '-s'. Ex:
             'cat ./somefile.sh | yadshot -p -s sh'

yadshot -t   Open a system tray app for quick access to yadshot.
"
}

case $1 in
    -h|--help)
        yadshothelp
        exit 0
        ;;
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
                yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="Paste uploaded to $PASTE_URL"
            fi
        else
            yadshotpaste
            exit 0
        fi
        ;;
    -f|--file)
        FILE="$(yad --file $PWD --center --title=yadshot --height 600 --width 800)"
        case $? in
            0)
                yadshotupload "$FILE"
                ;;
            *)
                exit 0
                ;;
        esac
        ;;
    -c|--capture)
        yadshotcapture
        displayss
        exit 0
        ;;
    -t|--tray)
        bash -c 'yadshottray'
        ;;
    *)
        startfunc
        ;;
esac
