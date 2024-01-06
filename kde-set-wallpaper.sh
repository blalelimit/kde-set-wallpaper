#!/usr/bin/bash

# SETS WALLPAPER TO IMAGE OR SLIDESHOW
# Default wallpaper path set to ~/.local/share/wallpapers
mode="$1"
path="$HOME/.local/share/wallpapers"

# SHOWS EXAMPLES
if [[ ${#mode} -lt 2 ]]; then
	printf "Input empty or too short\n\nExamples:\nwallp in\t- Shows Wallpaper Information\nwallp ss\t- sets Wallpaper Slideshow\nwallp arch\t- sets Wallpaper Image \"arch.png\"\nwallp rd\t- sets Random Wallpaper Image\nwallp wekde\t- sets Wallpaper Engine\n";
	exit 1
fi

case $mode in
	# SHOWS WALLPAPER INFORMATION
	"info"|"in")
		printf "Showing Information of Wallpaper\n\n"
		kwargs="
			print('Wallpaper Plugin: ' + d.wallpaperPlugin + '\n');
			d.currentConfigGroup = Array('Wallpaper', d.wallpaperPlugin, 'General');
			print('Wallpaper Image: ' + (d.readConfig('Image') || 'N/A' ) + '\n\n');
			print(Object.keys(d) + '\n\n');
			print(JSON.stringify(d));
		"
	;;

	# SETS WALLPAPER PLUGIN TO "SLIDESHOW", ALSO TRIGGERS NEXT WALLPAPER
    # Default interval set to 9000 seconds (2.5 hours)
	"slideshow"|"ss"|"all")
		echo "Wallpaper Slideshow was set"
		kwargs="
			d.wallpaperPlugin = 'org.kde.slideshow';
			d.currentConfigGroup = Array('Wallpaper', 'org.kde.slideshow', 'General');
			if (d.readConfig('SlideInterval') == 9000) {
				d.writeConfig('SlideInterval', 9001);
			}
			else {
				d.writeConfig('SlideInterval', 9000);
			}
		"
	;;

	# SETS WALLPAPER PLUGIN TO "WALLPAPER ENGINE"
    # Must first install KDE Wallpaper Engine Plugin to use this
	# "engine"|"wekde")
	# 	echo "Wallpaper Engine was set"
	# 	kwargs="
	# 		d.wallpaperPlugin = 'com.github.casout.wallpaperEngineKde';
	# 		d.currentConfigGroup = Array('Wallpaper', 'com.github.casout.wallpaperEngineKde', 'General');
	# 	"
	# ;;

	# SETS WALLPAPER PLUGIN TO "IMAGE", RANDOMLY
	"random"|"rd")
		file=$(ls ${path} | shuf -n1)
		echo "Random Wallpaper \"${file}\" was set"
		kwargs="
			d.wallpaperPlugin = 'org.kde.image';
			d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
			d.writeConfig('Image', 'file://${path}/${file}');
		"
	;;

	# SETS WALLPAPER PLUGIN TO "IMAGE", WHERE args[0] IS PASSED AS PATTERN TO GREP
	*)
		files=$(ls ${path} | grep ${mode})
		printf "Wallpaper Image was set\n"

		# SETS IMAGE TO RANDOM FROM ALL IMAGES IF PATTERN NOT FOUND
		if [[ ${files} == '' ]]; then
			printf "Pattern not found, defaulting to random\n\n"
			file=$(ls ${path} | shuf -n1)
		# SETS IMAGE RANDOMLY FROM LIST FILTERED BY GREP IF PATTERN IS FOUND
		else
			printf "\nPattern found, as listed below\n\n${files}\n\n"
			file=$(ls ${path} | grep ${mode} | shuf -n1)

		fi

		echo "Wallpaper \"${file}\" was set"
		kwargs="
			d.wallpaperPlugin = 'org.kde.image';
			d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
			d.writeConfig('Image', 'file://${path}/${file}');
		"
	;;
esac

wallpaper_set_script="
 		var allDesktops = desktops();
 		for (i=0; i<allDesktops.length; i++) {
			d = allDesktops[i];
			$kwargs
		}
	"

# USES qdbus TO CALL org.kde.plasmashell TO EXECUTE THE SCRIPT
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${wallpaper_set_script}"
