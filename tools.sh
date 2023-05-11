dl_gh() {
    for repo in revanced-patches revanced-cli revanced-integrations ; do
    asset_urls=$(wget -qO- "https://api.github.com/repos/$1/$repo/releases/latest" \
                 | jq -r '.assets[] | "\(.browser_download_url) \(.name)"')
        while read -r url names
        do
            echo "Downloading $names from $url"
            wget -q -O "$names" $url
        done <<< "$asset_urls"
    done
echo "All assets downloaded"
}
get_patches_key() {
    EXCLUDE_PATCHES=()
        for word in $(cat $1/exclude-patches) ; do
            EXCLUDE_PATCHES+=("-e $word")
        done
    INCLUDE_PATCHES=()
        for word in $(cat $1/include-patches) ; do
            INCLUDE_PATCHES+=("-i $word")
        done
}
req() { 
    wget -nv -O "$2" -U "Mozilla/5.0 (X11; Linux x86_64; rv:111.0) Gecko/20100101 Firefox/111.0" "$1"
}
get_apkmirror_vers() { 
    req "$1" - | sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p'
}
get_largest_ver() {
  local max=0
  while read -r v || [ -n "$v" ]; do   		
	if [[ ${v//[!0-9]/} -gt ${max//[!0-9]/} ]]; then max=$v; fi
	  done
      	if [[ $max = 0 ]]; then echo ""; else echo "$max"; fi
}
get_uptodown_resp() {
    req "${1}/versions" -
}

get_uptodown_vers() {
    sed -n 's;.*version">\(.*\)</span>$;\1;p' <<< "$1"
}
dl_apkmirror() {
  local url=$1 regexp=$2 output=$3
  url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
  echo "$url"
  url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
  url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
  req "$url" "$output"
}
dl_uptodown() {
    local uptwod_resp=$1 version=$2 output=$3
    local url
    url=$(grep -F "${version}</span>" -B 2 <<< "$uptwod_resp" | head -1 | sed -n 's;.*data-url="\(.*\)".*;\1;p') || return 1
    url=$(req "$url" - | sed -n 's;.*data-url="\(.*\)".*;\1;p') || return 1
    req "$url" "$output"
}
get_apkmirror() {
  echo "Downloading $1"
  local last_ver
  last_ver="$version"
  last_ver="${last_ver:-$(get_apkmirror_vers "https://www.apkmirror.com/uploads/?appcategory=$2" | get_largest_ver)}"
  echo "Choosing version '${last_ver}'"
  local base_apk="$1.apk"
  dl_url=$(dl_apkmirror "https://www.apkmirror.com/apk/$3-${last_ver//./-}-release/" \
			"APK</span>[^@]*@\([^#]*\)" \
			"$base_apk")
  echo "$1 version: ${last_ver}"
  echo "downloaded from: [APKMirror - $1]($dl_url)"
}
get_apkmirror_arch() {
  echo "Downloading $1 (${arm64-v8a})"
  local last_ver
  last_ver="$version"
  last_ver="${last_ver:-$(get_apkmirror_vers "https://www.apkmirror.com/uploads/?appcategory=$2" | get_largest_ver)}"
  echo "Choosing version '${last_ver}'"
  local base_apk="$1.apk"
  local regexp_arch='arm64-v8a</div>[^@]*@\([^"]*\)'
  dl_url=$(dl_apkmirror "https://www.apkmirror.com/apk/$3-${last_ver//./-}-release/" \
			"$regexp_arch" \
			"$base_apk")
  echo "$1 (${arm64-v8a}) version: ${last_ver}"
  echo "downloaded from: [APKMirror - $1 ${arm64-v8a}]($dl_url)"
}
get_uptodown() {
    Downloading $1
    local apk_name="$1"
    local link_name="$2"
    local version="$version"
    local out_name=$(echo "$apk_name" | tr '.' '_' | awk '{ print tolower($0) ".apk" }')
    local uptwod_resp
    uptwod_resp=$(get_uptodown_resp "https://${link_name}.en.uptodown.com/android")
    local available_versions=($(get_uptodown_vers "$uptwod_resp"))
    echo "Available versions: ${available_versions[*]}"
    if [[ " ${available_versions[@]} " =~ " ${version} " ]]; then
        echo "Downloading version $version"
        dl_uptodown "$uptwod_resp" "$version" "$out_name"
    else
        echo "Couldn't find specified version $version, downloading latest version"
        version=${available_versions[0]}
        echo "Downloading version $version"
        uptwod_resp=$(get_uptodown_resp "https://${link_name}.en.uptodown.com/android")
        dl_uptodown "$uptwod_resp" "$version" "$out_name"
    fi
}
#version="2023.16.0"
#get_uptodown "reddit" "reddit-official-app" (can't download twitter)
get_ver() {
    version=$(jq -r --arg patch_name "$1" --arg pkg_name "$2" '
    .[]
    | select(.name == $patch_name)
    | .compatiblePackages[]
    | select(.name == $pkg_name)
    | .versions[-1]
    ' patches.json)
}
patch() {
    if [ -f "$1.apk" ]; then
    java -jar revanced-cli*.jar \
    -m revanced-integrations*.apk \
    -b revanced-patches*.jar \
    -a $1.apk \
    ${EXCLUDE_PATCHES[@]} \
    ${INCLUDE_PATCHES[@]} \
    --keystore=ks.keystore \
    -o ./build/$2.apk
    unset version
    unset EXCLUDE_PATCHES
    unset INCLUDE_PATCHES
    else 
        exit 1
    fi
}
