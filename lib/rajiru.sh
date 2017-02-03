#!/bin/bash
# https://gist.github.com/soramugi/836952a6b09e540eb6a3 を参考に
# https://gist.github.com/matchy2/f03205246e1a12b3b027 をRaspberry Pi仕様にしました。

LANG=ja_JP.utf8

pid=$$
wkdir='/var/tmp'
playerurl="http://www3.nhk.or.jp/netradio/files/swf/rtmpe_ver2015.swf"
date=`date +%Y%m%d_%H%M`

# Usage
show_usage() {
  echo 'Usage:'
  echo ' RECORD MODE' 1>&2
  echo "   `basename $0` [-d out_dir] [-f file_name]" 1>&2
  echo '          [-t rec_minute] [-s Starting_position] channel' 1>&2
  echo '           -d  Default out_dir = $HOME' 1>&2
  echo '                  a/b/c = $HOME/a/b/c' 1>&2
  echo '                 /a/b/c = /a/b/c' 1>&2
  echo '                ./a/b/c = $PWD/a/b/c' 1>&2
  echo '           -f  Default file_name = channel_YYYYMMDD_HHMM_PID' 1>&2
  echo '           -t  Default rec_minute = 1' 1>&2
  echo '               60 = 1 hour, 0 = go on recording until stopped(control-C)' 1>&2
  echo '           -s  Default starting_position = 00:00:00' 1>&2
  echo ' PLAY MODE' 1>&2
  echo "   `basename $0` -p [-t play_minute] channel" 1>&2
  echo '           -p  Play mode. No recording.' 1>&2
}

# Record
record() {
  # rtmpdump
  rtmpdump \
    --rtmp $rtmp \
    --app "live" \
    --swfVfy $playerurl \
    --playpath $playpath \
    --live \
    --stop ${duration} \
    --flv "${wkdir}/${tempname}.flv"

  ffmpeg -ss ${starting} -i "${wkdir}/${tempname}.flv" \
    -acodec copy "${wkdir}/${tempname}.m4a" && \
    rm -f "${wkdir}/${tempname}.flv"

  mv -b "${wkdir}/${tempname}.m4a" "${outdir}/${filename}.m4a"

  if [ $? -ne 0 ]; then
    echo "[stop] failed move file (${wkdir}/${tempname}.m4a to \
      ${outdir}/${filename}.m4a)" 1>&2 ; exit 1
  fi
}

# Play
play() {
  # rtmpdump
  rtmpdump \
    --rtmp "${rtmp}/live/${playpath}" \
    --swfVfy $playerurl \
    --live \
    --buffer 250 \
    --flv - | \
    mplayer -ao alsa:device=plughw=1.0 -
}

# Get Option
while getopts pd:f:t:s: OPTION
do
  case $OPTION in
    p ) OPTION_p=true
      ;;
    d ) OPTION_d=true
      VALUE_d="$OPTARG"
      ;;
    f ) OPTION_f=ture
      VALUE_f="$OPTARG"
      ;;
    t ) OPTION_t=true
      VALUE_t="$OPTARG"
      if ! expr "${VALUE_t}" : '[0-9]*' > /dev/null ; then
        show_usage ; exit 1
      fi
      ;;
    s ) OPTION_s=ture
      VALUE_s="$OPTARG"
      ;;
    * ) show_usage ; exit 1 ;;
  esac
done

# Get Channel
shift $(($OPTIND - 1))
if [ $# -ne 1 ]; then
  show_usage ; exit 1
fi
channel=$1

#
# set channel
#
case $channel in
    "NHK1")
    rtmp="rtmpe://netradio-r1-flash.nhk.jp"
    playpath="NetRadio_R1_flash@63346"
    ;;
    "NHK2")
    rtmp="rtmpe://netradio-r2-flash.nhk.jp"
    playpath="NetRadio_R2_flash@63342"
    ;;
    "FM")
    rtmp="rtmpe://netradio-fm-flash.nhk.jp"
    playpath="NetRadio_FM_flash@63343"
    ;;
    "NHK1_SENDAI")
    rtmp="rtmpe://netradio-hkr1-flash.nhk.jp"
    playpath="NetRadio_HKR1_flash@108442"
    ;;
    "FM_SENDAI")
    rtmp="rtmpe://netradio-hkfm-flash.nhk.jp"
    playpath="NetRadio_HKFM_flash@108237"
    ;;
    "NHK1_NAGOYA")
    rtmp="rtmpe://netradio-ckr1-flash.nhk.jp"
    playpath="NetRadio_CKR1_flash@108234"
    ;;
    "FM_NAGOYA")
    rtmp="rtmpe://netradio-ckfm-flash.nhk.jp"
    playpath="NetRadio_CKFM_flash@108235"
    ;;
    "NHK1_OSAKA")
    rtmp="rtmpe://netradio-bkr1-flash.nhk.jp"
    playpath="NetRadio_BKR1_flash@108232"
    ;;
    "FM_OSAKA")
    rtmp="rtmpe://netradio-bkfm-flash.nhk.jp"
    playpath="NetRadio_BKFM_flash@108233"
    ;;
    *)
    echo "failed channel"
    exit 1
    ;;
esac

#
# RECORD Mode
#
if [ ! "${OPTION_p}" ]; then
  # Get Directory
  if [ ! "$OPTION_d" ]; then
    cd ${HOME}
  else
    if echo ${VALUE_d}|grep -q -v -e '^./\|^/'; then
      mkdir -p "${HOME}/${VALUE_d}"
      if [ $? -ne 0 ]; then
        echo "[stop] failed make directory (${HOME}/${VALUE_d})" 1>&2 ; exit 1
      fi
      cd "${HOME}/${VALUE_d}"
    else
      mkdir -p ${VALUE_d}
      if [ $? -ne 0 ]; then
        echo "[stop] failed make directory (${VALUE_d})" 1>&2 ; exit 1
      fi
      cd ${VALUE_d}
    fi
  fi
  outdir=${PWD}

  # Get File Name
  filename=${VALUE_f:=${channel}_${date}_${pid}}
  tempname=${channel}_${pid}

  # Get Minute
  min=${VALUE_t:=1}
  duration=`expr ${min} \* 60`

  # Get Starting Position
  starting=${VALUE_s:='00:00:00'}

  # Start Recording
  record

  #
  # PLAY Mode
  #
else
  # Start Playing
  play

fi
