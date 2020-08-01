#!/bin/bash

alive=1
#vlc='/Applications/VLC.app/Contents/MacOS/VLC'		# specifické pro MacOS
timer=3600						# Doba ve vteřinách
cesta='/tmp/Zaznamy'					# Cesta k uložení záznamů .. na macu '/Volumes/Expansion/Záznam' # path to recordings
((scheduler=1))
((opscounter=0))
mkdir /tmp/Zaznamy

clear

function mailsender
{
	cat $logfile | mail -a "Content-Type: text/plain; charset=UTF-8" -s "Status Reporter: $(hostname)" email@domain.tld
}

function nahravej #means record
{
#vlc rtsp://192.168.1.11/user=admin_password=_channel=1_stream=0.sdp --sub-filter=marq --marq-marquee='%Y-%m-%d %H:%M:%S' --marq-position=5 --marq-refresh=-1 --marq-size=15 --sout='#std{access=file,mux=mp4,dst= &cesta/%Y-%m-%d-%H%M.mp4}}' --run-time 3602 vlc://quit #ty dvě vteřiny jsou kvůli navázání spojení
echo "NIC TU NENÍ"
}

function reporter
{
	logfile='/tmp/report.log'

	function baterie
	{
		#battinfo=$(pmset -g batt) # specifické pro MacOS
		battinfo=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|to\ full|percentage") # specifické pro ubuntu
	}

	echo -e " > Vytvářím logovací soubor (umístění: $logfile)"
	echo -ne "[....................] 0% \r"

	echo "				> LOG file <" > $logfile
	echo -e "\n> Hostname: $(hostname)		Logged on user: $(whoami)\nAll logged on users: \n$(who)" >> $logfile

		sleep 0.01;	echo -ne "[=====...............] 25%\r"

	echo -e "\n> Uptime: \n$(uptime)" >> $logfile

		sleep 0.01;	echo -ne "[==========..........] 50%\r"

	baterie
	echo -e "\n> Battery info: \n$battinfo" >> $logfile

		sleep 0.01;	echo -ne "[===============.....] 75%\r"

	echo -e "\n> Disk info: \n$(df -h)" >> $logfile
	echo -e "\n> Generated: $(date +"%D %T")" >> $logfile
	echo -e "\n> OPScounter: $opscounter	Scheduler: $scheduler" >> $logfile

		sleep 0.01;	echo -ne "[====================] 100%\n"
}

###########################################



while [ $alive -eq 1 ]
do
	echo -e " >> Skript pro mazání starých huso-kachních záznamů <<\n i- 1x za den budou smazány všechny soubory starší než 7 dní."

	if [ $scheduler -eq 12 ]
		then
			clear
			nahravej
			((scheduler=1)) ; ((opscounter++))
			find $cesta -mindepth 1 -mtime +7 | xargs rm -rf
			echo -e " > Mazání bylo dokončeno $(date +"%D %T") \n > Další mazání proběhne za 24 h"
			reporter ; echo -e "\n!> CLEANING HAS BEEN PERFORMED\n" >> $logfile
			mailsender
			sleep $timer # probably not required
		else
			((scheduler++)) ; ((opscounter++))
			nahravej
			reporter
			mailsender
			sleep $timer # probably not required
	fi
done




#########################################
#toto by mělo být funkční nahrávání:
#vlc rtsp://192.168.1.11/user=admin_password=_channel=1_stream=0.sdp --sub-filter=marq --marq-marquee='%Y-%m-%d %H:%M:%S' --marq-position=5 --marq-refresh=-1 --marq-size=15 --sout='#std{access=file,mux=mp4,dst=/tmp/%Y-%m-%d-%H%M.mp4}}' --run-time 9 vlc://quit

###favorite:
#rtsp://192.168.1.11/user=admin_password=_channel=1_stream=0.sdp


#http://cdkr.co.uk/projects/computers/vlc_batch_recorder/
#records 61min long time stamped clip, then kills itself. 
#cvlc -v --no-osd --no-embedded-video rtsp://localhost:8080/vid0.sdp --sout='#std{access=file,mux=mp4,dst=/var/recordings/recorder0/%Y-%m-%d-%H%M.mp4}}' --run-time 3660 vlc://quit

#cvlc v4l2:///dev/video0:width=352:height=292 --quiet-synchro --no-osd --sub-filter=marq --marq-marquee='%Y-%m-%d %H:%M:%S' --marq-position=5 --marq-refresh=-1 --marq-size=15 --sout '#transcode{venc=x264{keyint=60,profile=main},vcodec=x264,vb=100,scale=0.5,sfilter=marq}:rtp{sdp=rtsp://:8080/cctv.sdp}' :no-sout-rtp-sap :no-sout-standard-sap :sout-keep
