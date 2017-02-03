#!/bin/bash

#############################################
#
# matchy2/rec_radiko.sh
# https://gist.github.com/matchy2/3956266
# まっつん/radiko.sh
# https://mtunn.wordpress.com/odroid-u2★セットアップ/radikoの録音・再生（archlinux）/
#
# Mod by Oyakodon
# http://oykdn.com/
# 2017 (c) Oyakodon
#
# radiko仕様変更対応済み( 2017-2-3 )
#
#############################################

LANG=ja_JP.utf8

pid=$$
date=`date '+%Y-%m-%d-%H_%M'`
wkdir='/var/tmp'
outdir="."

# Depend on radiko.jp's specification.
playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf
playerfile="${wkdir}/player.swf"
keyfile="${wkdir}/authkey.png"

#############################################
# Usage
show_usage() {
  echo 'Usage:'
  echo ' RECORD MODE' 1>&2
  echo "   `basename $0` [-d out_dir] [-f file_name]" 1>&2
  echo '          [-t rec_minute] [-s Starting_position] channel' 1>&2
  echo '           -d  Default out_dir = $HOME' 1>&2
  echo '           -f  Default file_name = channel_YYYYMMDD_HHMM_PID' 1>&2
  echo '           -t  Default rec_minute = 1' 1>&2
  echo '               60 = 1 hour, 0 = go on recording until stopped(control-C)' 1>&2
  echo '           -s  Default starting_position = 00:00:00' 1>&2
  echo ' PLAY MODE' 1>&2
  echo "   `basename $0` -p [-t play_minute] channel" 1>&2
  echo '           -p  Play mode. No recording.' 1>&2
  echo '           -t  Default play_minute = 0' 1>&2
  echo '               60 = 1 hour, 0 = go on recording until stopped(control-C)' 1>&2
}

#############################################
# Authorize
Authorize() {
  #
  # get player
  #
  if [ ! -f $playerfile ]; then
    wget -q -O $playerfile $playerurl

    if [ $? -ne 0 ]; then
      echo "failed get player"
      exit 1
    fi
  fi

  #
  # get keydata (need swftool)
  #
  if [ ! -f $keyfile ]; then
    swfextract -b 12 $playerfile -o $keyfile

    if [ ! -f $keyfile ]; then
      echo "failed get keydata"
      exit 1
    fi
  fi

  if [ -f auth1_fms_${pid} ]; then
    rm -f auth1_fms_${pid}
  fi

  #
  # access auth1_fms
  #
  wget -q \
      --header="pragma: no-cache" \
      --header="X-Radiko-App: pc_ts" \
      --header="X-Radiko-App-Version: 4.0.0" \
      --header="X-Radiko-User: test-stream" \
      --header="X-Radiko-Device: pc" \
      --post-data='\r\n' \
      --no-check-certificate \
      --save-headers \
      -O auth1_fms_${pid} \
      https://radiko.jp/v2/api/auth1_fms

  if [ $? -ne 0 ]; then
    echo "failed auth1 process"
    exit 1
  fi

  #
  # get partial key
  #   
  authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' auth1_fms_${pid}`
  offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' auth1_fms_${pid}`
  length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' auth1_fms_${pid}`

  partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

  #echo "authtoken: ${authtoken} \noffset: ${offset} length: ${length} \npartialkey: $partialkey"

  rm -f auth1_fms_${pid}

  if [ -f auth2_fms_${pid} ]; then  
    rm -f auth2_fms_${pid}
  fi

  #
  # access auth2_fms
  #
  wget -q \
      --header="pragma: no-cache" \
      --header="X-Radiko-App: pc_ts" \
      --header="X-Radiko-App-Version: 4.0.0" \
      --header="X-Radiko-User: test-stream" \
      --header="X-Radiko-Device: pc" \
      --header="X-Radiko-AuthToken: ${authtoken}" \
      --header="X-Radiko-PartialKey: ${partialkey}" \
      --post-data='\r\n' \
      --no-check-certificate \
      -O auth2_fms_${pid} \
      https://radiko.jp/v2/api/auth2_fms

  if [ $? -ne 0 -o ! -f auth2_fms_${pid} ]; then
    echo "failed auth2 process"
    exit 1  
  fi

  #echo "authentication success"

  areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' auth2_fms_${pid}`
  #echo "areaid: $areaid"

  rm -f auth2_fms_${pid}

  #
  # get stream-url
  #

  if [ -f ${channel}.xml ]; then
    rm -f ${channel}.xml
  fi

  wget -q "http://radiko.jp/v2/station/stream/${channel}.xml"

  stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell ${channel}.xml | tail -2 | head -1`
  url_parts=(`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!$1://$2 $3 $4!'`)

  rm -f ${channel}.xml

} # end of Authorize

#############################################
# Record
Record() {
  # rtmpdump
  rtmpdump \
        -r ${url_parts[0]} \
        --app ${url_parts[1]} \
        --playpath ${url_parts[2]} \
        -W $playerurl \
        -C S:"" -C S:"" -C S:"" -C S:$authtoken \
        --live \
        --stop ${DURATION} \
        --flv "/tmp/${channel}_${date}"

  ffmpeg -loglevel quiet -y -ss "${starting}" -i "/tmp/${channel}_${date}" -acodec libmp3lame -ab 128k "${outdir}/${filename}.mp3"
  if [ $? = 0 ]; then
    echo "[ffmpeg] convert failed."
    rm -f "/tmp/${channel}_${date}"
  fi
} # end of Record

#############################################
# Play
Play() {
  # rtmpdump
  rtmpdump \
    -r ${url_parts[0]} \
    --app ${url_parts[1]} \
    --playpath ${url_parts[2]} \
    -W $playerurl \
    -C S:"" -C S:"" -C S:"" -C S:$authtoken \
    --live \
    --stop ${DURATION} | \
    mplayer -ao alsa:device=plughw=1.0 -
} # end of Play

#############################################
# Main
# Get Options
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

if [ ! "${OPTION_p}" ]; then
  #
  # RECORD Mode
  #

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

  # Get File Name (if VALUE_f not set, set default path = "${channel}_${date}_${pid}")
  filename=${VALUE_f:=${channel}_${date}_${pid}}

  # Get Minute(s)
  min=${VALUE_t:=1}
  DURATION=`expr ${min} \* 60`

  # Get Starting Position
  starting=${VALUE_s:='00:00:00'}

  Authorize && Record

else
  #
  # PLAY Mode
  #

  # Get Minute(s)
  DURATION=`expr ${VALUE_t:=0} \* 60`

  Authorize && Play

fi

# end of Main
