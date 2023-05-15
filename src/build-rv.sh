#!/bin/bash
# Revanced build
source ./src/tools.sh
release=$(curl -s "https://api.github.com/repos/revanced/revanced-patches/releases/latest")
asset=$(echo "$release" | jq -r '.assets[] | select(.name | test("revanced-patches.*\\.jar$")) | .browser_download_url')
curl -sL -O "$asset"
ls revanced-patches*.jar >> new.txt
rm -f revanced-patches*.jar
#release=$(curl -s "https://api.github.com/repos/gocmodup/revanced/releases/latest")
asset=$(echo "$release" | jq -r '.assets[] | select(.name == "revanced-version.txt") | .browser_download_url')
curl -sL -O "$asset"
if diff -q revanced-version.txt new.txt >/dev/null ; then
rm -f *.txt
echo "Old patch!!! Not build"
exit 0
else
rm -f *.txt
dl_gh "revanced" "revanced-patches revanced-cli revanced-integrations" "latest"
# Messenger
get_patches_key "messenger"
#get_apkmirror_arch "messenger" "messenger" "facebook-2/messenger/messenger"
get_uptodown "messenger" "facebook-messenger"
patch "messenger" "messenger-revanced"
# Patch Instagram
get_patches_key "instagram"
#version="271.1.0.21.84" 
#get_apkmirror_arch "instagram" "instagram" "/instagram/instagram-instagram"
get_uptodown "instagram" "instagram"
patch "instagram" "instagram-revanced"
# Patch Twitch 
get_patches_key "twitch"
get_ver "block-video-ads" "tv.twitch.android.app"
get_apkmirror "twitch" "twitch" "twitch-interactive-inc/twitch/twitch"
#get_uptodown "twitch" "twitch"
patch "twitch" "twitch-revanced"
# Patch Tiktok 
get_patches_key "tiktok"
get_ver "sim-spoof" "com.ss.android.ugc.trill"
get_apkmirror "tiktok" "tik-tok-including-musical-ly" "tiktok-pte-ltd/tik-tok-including-musical-ly/tik-tok-including-musical-ly"
#get_uptodown "tiktok" "tik-tok"
patch "tiktok" "tiktok-revanced"
# Patch YouTube 
get_patches_key "youtube-revanced"
get_ver "video-ads" "com.google.android.youtube"
get_apkmirror "youtube" "youtube" "google-inc/youtube/youtube"
#get_uptodown "youtube" "youtube" 
patch "youtube" "youtube-revanced"
# Patch YouTube Music 
get_patches_key "youtube-music-revanced"
get_ver "hide-get-premium" "com.google.android.apps.youtube.music"
get_apkmirror_arch "youtube-music" "youtube-music" "google-inc/youtube-music/youtube-music"
#get_uptodown "youtube-music" "youtube-music" 
patch "youtube-music" "youtube-music-revanced"
ls revanced-patches*.jar >> revanced-version.txt
fi
