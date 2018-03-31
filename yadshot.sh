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
export -f yadshottray

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
            "$RUNNING_DIR"/yadshot.sh -c
            ;;
    esac
}

function yadshotpaste() {
    PASTE_SETTINGS="$(yad --center --title="yadshot" --height=600 --width=600 --form --separator="," --borders="10" --no-markup --scroll \
    --button="Ok"\!gtk-ok --button="Cancel"\!gtk-cancel:1 --field="Paste Title:":CE "yadshot-$(date +%F)-$(date +%T)" \
    --field="Paste Syntax":CB "abap!abnf!as!as3!ada!adl!agda!aheui!alloy!at!ampl!ng2!antlr!antlr-as!antlr-csharp!antlr-cpp!antlr-java!antlr-objc!antlr-perl!antlr-python!antlr-ruby!apacheconf!apl!applescript!arduino!aspectj!aspx-cs!aspx-vb!asy!ahk!autoit!awk!basemake!bash!console!bat!bbcode!bc!befunge!bib!blitzbasic!blitzmax!bnf!boo!boogie!brainfuck!bro!bst!bugs!c!csharp!cpp!ca65!cadl!camkes!capdl!capnp!cbmbas!ceylon!cfengine3!cfs!chai!chapel!cheetah!cirru!clay!clean!clojure!clojurescript!cmake!c-objdump!cobol!cobolfree!coffee-script!cfc!cfm!common-lisp!componentpascal!coq!cpp-objdump!cpsa!crmsh!croc!cryptol!cr!csound-document!csound!csound-score!css!css+django!css+genshitext!css+lasso!css+mako!css+mozpreproc!css+myghty!css+php!css+erb!css+smarty!cuda!cypher!cython!d!dpatch!dart!control!sourceslist!delphi!dg!diff!django!d-objdump!docker!dtd!duel!dylan!dylan-console!dylan-lid!earl-grey!easytrieve!ebnf!ec!ecl!eiffel!elixir!iex!elm!emacs!ragel-em!erb!erlang!erl!evoque!ezhil!factor!fancy!fan!felix!fish!flatline!forth!fortran!fortranfixed!foxpro!fsharp!gap!gas!genshi!genshitext!pot!cucumber!glsl!gnuplot!go!golo!gooddata-cl!gosu!gst!groff!groovy!haml!handlebars!haskell!hx!hexdump!hsail!html!html+ng2!html+cheetah!html+django!html+evoque!html+genshi!html+handlebars!html+lasso!html+mako!html+myghty!html+php!html+smarty!html+twig!html+velocity!http!haxeml!hylang!hybris!idl!idris!igor!inform6!i6t!inform7!ini!io!ioke!irc!isabelle!j!jags!jasmin!java!jsp!js!js+cheetah!js+django!js+genshitext!js+lasso!js+mako!javascript+mozpreproc!js+myghty!js+php!js+erb!js+smarty!jcl!jsgf!json!json-object!jsonld!julia!jlcon!juttle!kal!kconfig!koka!kotlin!lasso!lean!less!lighty!limbo!liquid!lagda!lcry!lhs!lidr!live-script!llvm!logos!logtalk!lsl!lua!make!mako!maql!md!mask!mason!mathematica!matlab!matlabsession!minid!modelica!modula2!trac-wiki!monkey!monte!moocode!moon!mozhashpreproc!mozpercentpreproc!mql!mscgen!doscon!mupad!mxml!myghty!mysql!nasm!ncl!nemerle!nesc!newlisp!newspeak!nginx!nim!nit!nixos!nsis!numpy!nusmv!objdump!objdump-nasm!objective-c!objective-c++!objective-j!ocaml!octave!odin!ooc!opa!openedge!pacmanconf!pan!parasail!pawn!perl!perl6!php!pig!pike!pkgconfig!plpgsql!psql!postgresql!postscript!pov!powershell!ps1con!praat!prolog!properties!protobuf!pug!puppet!pypylog!python!python3!py3tb!pycon!pytb!qbasic!qml!qvto!racket!ragel!ragel-c!ragel-cpp!ragel-d!ragel-java!ragel-objc!ragel-ruby!raw!rconsole!rd!rebol!red!redcode!registry!rnc!resource!rst!rexx!rhtml!roboconf-graph!roboconf-instances!robotframework!spec!rql!rsl!rb!rbcon!rust!splus!sas!sass!scala!ssp!scaml!scheme!scilab!scss!shen!silver!slim!smali!smalltalk!smarty!snobol!snowball!sp!sparql!sql!sqlite3!squidconf!stan!sml!stata!sc!swift!swig!systemverilog!tads3!tap!tasm!tcl!tcsh!tcshcon!tea!termcap!terminfo!terraform!tex!text!thrift!todotxt!rts!tsql!treetop!turtle!twig!ts!typoscript!typoscriptcssdata!typoscripthtmldata!urbiscript!vala!vb.net!vcl!vclsnippets!vctreestatus!velocity!verilog!vgl!vhdl!vim!wdiff!whiley!x10!xml!xml+cheetah!xml+django!xml+evoque!xml+lasso!xml+mako!xml+myghty!xml+php!xml+erb!xml+smarty!xml+velocity!xquery!xslt!xtend!extempore!xul+mozpreproc!yaml!yaml+jinja!zephir" \
    --field="Paste Contents:":LBL "Paste Contents:" --field="$(xclip -o -selection clipboard)":LBL "$(xclip -o -selection clipboard)")"
    case $? in
        0)
            sleep 0
            ;;
        *)
            exit 0
            ;;
    esac
    PASTE_TITLE="$(echo -e $PASTE_SETTINGS | cut -f1 -d',')"
    PASTE_SYNTAX="$(echo -e $PASTE_SETTINGS | cut -f2 -d',')"
    PASTE_TEXT="$(xclip -o -selection clipboard)"
    PASTE_URL="$(curl -s --data "title=$PASTE_TITLE&syntax=$PASTE_SYNTAX" --data-urlencode "code=$PASTE_TEXT" https://api.teknik.io/v1/Paste | cut -f10 -d'"')"
    if [ -z "$PASTE_URL" ]; then
        yad --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
        exit 1
    else
        echo -n "$PASTE_URL" | xclip -i -selection primary
        echo -n "$PASTE_URL" | xclip -i -selection clipboard
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
                            "$RUNNING_DIR"/teknik.sh "$FILE"
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

case $1 in
    -p*|--p*|-s*|--s*)
        shift
        for ARG in "$@"; do
            case "$ARG" in
                -t|--title)
                    shift
                    PASTE_TITLE="$1"
                    shift
                    ;;
                -s|--syntax)
                    shift
                    PASTE_SYNTAX="$1"
                    shift
                    ;;
            esac
        done
        if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
            while read -r line; do
                echo -e "$line"
            done | xclip -i -selection clipboard
            [ -z "$PASTE_TITLE" ] && PASTE_TITLE="yadshot-$(date +%F)-$(date +%T)"
            [ -z "$PASTE_SYNTAX" ] && PASTE_SYNTAX="text"
            PASTE_TEXT="$(xclip -o -selection clipboard)"
            PASTE_URL="$(curl -s --data "title=$PASTE_TITLE&syntax=$PASTE_SYNTAX" --data-urlencode "code=$PASTE_TEXT" https://api.teknik.io/v1/Paste | cut -f10 -d'"')"
            if [ -z "$PASTE_URL" ]; then
                yad --center --height=150 --borders=10 --info --title="yadshot" --button=gtk-ok --text="Failed to upload paste!"
                exit 1
            else
                echo -n "$PASTE_URL" | xclip -i -selection primary
                echo -n "$PASTE_URL" | xclip -i -selection clipboard
                yad --center --height=150 --borders=10 --info --selectable-labels --title="yadshot" --button=gtk-ok --text="Paste uploaded to $PASTE_URL"
            fi
        else
            yadshotpaste
            exit 0
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
        bash -c 'yadshottray'
        ;;
    *)
        startfunc
        ;;
esac
