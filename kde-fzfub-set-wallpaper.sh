#!/usr/bin/bash

# SET WALLPAPER AS IMAGE WITH FZF & UEBERZUGPP
# Default wallpaper path set to ~/.local/share/wallpapers
main_path="$HOME/.local/share/wallpapers"
mode=$(printf '%s\n' "image" "slideshow" "random" | fzf --cycle)

# SET WALLPAPER AS IMAGE SCRIPT
wallpaper_image() {
    wallpaper_script="
 	    var allDesktops = desktops();
 	    for (i=0; i<allDesktops.length; i++) {
		    d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://${file}');
        }
    "
    echo "Wallpaper Image \"${file}\" was set"
}

# SET WALLPAPER AS SLIDESHOW SCRIPT
wallpaper_slideshow() {
     wallpaper_script="
 	    var allDesktops = desktops();
 	    for (i=0; i<allDesktops.length; i++) {
		    d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.slideshow';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.slideshow', 'General');
            if (d.readConfig('SlideInterval') == 9000) {
                d.writeConfig('SlideInterval', 9001);
            }
            else {
                d.writeConfig('SlideInterval', 9000);
            }

        }
    "
    echo "Wallpaper Slideshow was set"
}

# CHECK IF FILE IS AN IMAGE
check_if_image() {
    type=$(file -b --mime-type "${file}")

    case ${type} in
        "image/png"|"image/jpeg"|"image/webp")
            echo "File \"${file}\" is an image, continuing"
        ;;
        *)
            echo "File \"${file}\" is NOT an image, exiting"
            exit 1
        ;;
    esac
}

# PREPARE FZFUB (FZF UEBERGUZPP)
fzfub() {
    case "$(uname -a)" in
        *Darwin*) UEBERZUG_TMP_DIR="$TMPDIR" ;;
        *) UEBERZUG_TMP_DIR="/tmp" ;;
    esac

    cleanup() {
        ueberzugpp cmd -s "$SOCKET" -a exit
    }
    trap cleanup HUP INT QUIT TERM EXIT

    UB_PID_FILE="$UEBERZUG_TMP_DIR/.$(uuidgen)"
    ueberzugpp layer --no-stdin --silent --use-escape-codes --pid-file "$UB_PID_FILE"
    UB_PID=$(cat "$UB_PID_FILE")

    export SOCKET="$UEBERZUG_TMP_DIR"/ueberzugpp-"$UB_PID".socket
    export X=$(($(tput cols) / 2 + 2))
    export Y=$(($(tput lines) / 2 - 17))
    max_width=73
    max_height=35

    # SET IMAGES PATH, THEN FOLLOW SYMBOLIC LINKS ON FIND
    file=$(find -L $main_path -type f | fzf --cycle --preview="ueberzugpp cmd -s $SOCKET -i fzfpreview -a add -x $X -y $Y --max-width $max_width --max-height $max_height -f {}")

    # CLOSE UEBERZUGPP SOCKET
    ueberzugpp cmd -s "$SOCKET" -a exit
    rm "$UB_PID_FILE"

    # EXITS IF NO IMAGE IS SELECTED
    if [[ ${file} = "" ]]; then
        exit 1
    fi
}

# SELECT WALLPAPER MODEE
case $mode in
    # EXITS IF NO MODE IS SELECTED
    "")
        exit 1
    ;;
    # SETS WALLPAPER PLUGIN TO IMAGE, SELECT IMAGE USING FZFUB (FZF UEBERZUGPP)
    "image")
        fzfub
        check_if_image
        wallpaper_image

    ;;
	# SETS WALLPAPER PLUGIN TO SLIDESHOW, ALSO TRIGGERS NEXT WALLPAPER
    "slideshow")
	    wallpaper_slideshow
    ;;
    # SETS WALLPAPER PLUGIN TO IMAGE, RANDOMLY SELECT IMAGE
    "random")
        file=$(find "$HOME/.local/share/wallpapers" | shuf -n1)
        check_if_image
        wallpaper_image
    ;;
esac

# USES qdbus TO CALL org.kde.plasmashell TO EXECUTE THE SCRIPT
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${wallpaper_script}"
