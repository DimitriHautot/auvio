#!/bin/bash

read -r -p "URL: " url
if [[ -z "$url" ]]; then
    echo "Invalid input..."
    echo "Quit"
    exit 1
fi

TITLE_VIDEO=$(youtube-dl --get-filename -o "%(title)s.%(ext)s" "$url" )
echo "TITLE_VIDEO: '$TITLE_VIDEO'"

DIRECTORY=$( echo "$TITLE_VIDEO" | tr -d -c ".[:alnum:]" )
read -r -p "Dossier de travail ($DIRECTORY): " input
DIRECTORY=${input:-$DIRECTORY}

mkdir "$DIRECTORY"
echo "Dossier de travail: $DIRECTORY"
cd "$DIRECTORY"
echo "$url" >> ./url.txt

if [ ! -f "$TITLE_VIDEO" ]; then
  echo "Téléchargement de la vidéo..."
  youtube-dl --keep-fragments --output "%(title)s.%(ext)s" --write-description --write-info-json --write-annotations --write-sub --write-thumbnail  "$url"
else
  echo "la vidéo est déjà présente"
fi

youtube-dl --list-formats "$url"
all_audio=$(youtube-dl --list-formats "$url" | grep "audio only" | awk '{print$1}')
echo "All audio formats: $all_audio"

for n in $all_audio; do
  echo "Téléchargement de la piste audio '$n'..."
  youtube-dl -k -f $n --keep-fragments --extract-audio --output $n".%(ext)s" "$url"
done

all_subtitles=$( youtube-dl --list-subs "$url" )
echo "Tous les sous-titres:\n$all_subtitles"
echo "Téléchargement de tous les sous-titres..."
youtube-dl --all-subs --skip-download --keep-fragments "$url"

FILES=$( find . -maxdepth 1 -iname "*.opus" -o -iname "*.m4a" -o -iname "*.vtt" -o -iname "*.srt"  | sed -e 's/.\///g' | awk '{ printf " "$0" "}' )
echo "Fichiers: '$FILES'"
MAP_ALL=$( find . -maxdepth 1 -iname "*.m4a" -o -iname "*.opus" -o -iname "*.vtt" -o -iname "*.srt" | sed -e 's/.\///g' | awk '{printf("%01d %s\n", NR, $0)}' | awk '{ printf " -map "$1" "}' )
echo "Mappings: '$MAP_ALL'"

if [[ ! -z "$MAP_ALL" ]]; then
    echo "Multiplexing..."
    ffmpeg -i "$TITLE_VIDEO" $FILES -map 0 "$MAP_ALL" -c copy -y "$TITLE_VIDEO".mkv
fi

cd ..
echo "URL: $url"
echo "Directory: $DIRECTORY"
ls -lS "$DIRECTORY"

~/bin/push-to-iphone.sh "auvio-dl.sh" "Téléchargement terminé (${DIRECTORY}/${TITLE_VIDEO}) - prêt à encoder en HEVC"


