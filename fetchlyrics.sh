#!/bin/bash

if dbus-send --print-reply \
	--session \
	--dest=org.mpris.MediaPlayer2.spotify \
	/org/mpris/MediaPlayer2 \
	org.freedesktop.DBus.Properties.Get \
	string:'org.mpris.MediaPlayer2.Player' \
	string:'Metadata' > /dev/null 2>&1 
then
	mkdir /tmp/lyrics
	touch /tmp/lyrics/dummy
	while [[ true ]] 
	do
		SONG=$(dbus-send --print-reply \
			--session \
			--dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.freedesktop.DBus.Properties.Get \
			string:'org.mpris.MediaPlayer2.Player' \
			string:'Metadata' | grep title -A 1 |tail -n 1 |cut -c 43-| sed 's/"*"//g')

		ARTIST=$(dbus-send --print-reply \
			--session \
			--dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.freedesktop.DBus.Properties.Get \
			string:'org.mpris.MediaPlayer2.Player' \
			string:'Metadata' | grep albumArtist -A 2 | tail -n 1 | cut -c 26- | sed 's/"*"//g')
		NAMECLN=$(echo "$ARTIST-$SONG" | sed -e 's/\(.*\)/\L\1/' \
			-e 's/[\.\,\(\)\+?\x27]//g' \
			-e 's/ feat .*//g' \
			-e 's/ /-/g')-lyrics 
		if [[ -e /tmp/lyrics/$NAMECLN ]]
		then
			sleep 1
		else
			clear
			echo "$ARTIST - $SONG"
			rm /tmp/lyrics/*
			wget -q https://genius.com/$NAMECLN -O /tmp/lyrics/$NAMECLN > /dev/null
			cat /tmp/lyrics/$NAMECLN \
				| grep -e '<br>' -e '</a>' -e '</p>' \
				|tr -d "\n" \
				|sed 's/<\/p>.*//' \
				|sed 's/<br>/\n/g' \
				|sed -e 's/.*@genius.*>//g' \
				-e 's/}[^>]*>//g' \
				-e 's/<[^>]*>//g' \
				-e 's/    //g' \
				-e 's/<a.*{//g' 
		fi
	done
else
	echo "Could not connect to Spotify"
fi
rm -rf /tmp/lyrics
