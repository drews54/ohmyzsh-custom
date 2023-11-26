function morse2beep
{
	echo "$@" | /usr/bin/morse -s | /usr/share/doc/beep/contrib/morse2beep.pl | xargs beep
}
function upd
{
	setopt xtrace
	paru
	sudo findpkg --update
	tldr --update
	sudo updatedb
}
function sup
{
	echo "Hello again!"
	echo "\nUptime stats:"
	uptime
	echo "\nLast 10 logins:"
	last -n 10
	if read -qs "reply?Update packages? (y/N): "
	then
		echo $reply
		upd
	else
		echo $reply
		echo "Not updating."
	fi
}
function is_hvc1 {
  local quiet=false

  while getopts 'q' opt
  do
    case "$opt" in
      q) quiet=true
      ;;
      \?) return 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ $(ffprobe -v error -select_streams v:0 -show_entries stream=codec_tag_string -of default=noprint_wrappers=1:nokey=1 "$@" 2>&1) == hvc1 ]]
  then
    if [[ $quiet == false ]]; then echo "$@ is in hvc1 format"; fi
    return 0
  else
    if [[ $quiet == false ]]; then echo "$@ is not in hvc1 format"; fi
    return 1
  fi
}
function to_hvc1 {
  local force=false
  local debug=false
  local encoder=x265
  local copy_audio=true

  while getopts 'fdc:a' opt
  do
    case "$opt" in
      f) force=true;;
      d) debug=true;;
      c) if [[ -n "$OPTARG" ]]
         then
           case "$OPTARG" in
             x265|nvenc) encoder="$OPTARG";;
             *) echo "$OPTARG is not a supported encoder" >&2
                if [[ $debug == true ]]; then return 1
                else echo "Using default encoder $encoder"; fi;;
           esac
         fi;;
      a) copy_audio=false;;
      \?) if [[ $debug == true ]]; then return 1; fi;;
    esac
  done

  shift $((OPTIND - 1))

  local ffmpeg_params
  if   [[ $encoder == x265  ]]; then ffmpeg_params='-hide_banner -i "%s" -c:v libx265 -preset slow -tag:v hvc1 -map_metadata 0 "%s"'
  elif [[ $encoder == nvenc ]]; then ffmpeg_params='-hide_banner -hwaccel cuda -hwaccel_output_format cuda -i "%s" -c:v hevc_nvenc -preset p7 -b_ref_mode disabled -tag:v hvc1 -map_metadata 0 "%s"'
  else echo "Somehow $encoder got past validation to the converter..." >&2; return 1
  fi
  [[ $copy_audio == true ]] && ffmpeg_params=$(echo $ffmpeg_params | sed 's/\("%s"\)\([^"%s"]*\)$/-c:a copy \1\2/')

  for video in "$@"
  do
    if is_hvc1 -q "$video"
    then
      echo "Skipping $video"
      continue
    fi

    printf $ffmpeg_params $video ${video%.*}.hvc1.mp4 | xargs -o ffmpeg

    if [[ $? == 0 ]]
    then
      touch -r "$video" "${video%.*}.hvc1.mp4"
      local result="Converted $video to hvc1 format"
      if [[ $force == true ]]
      then
        rm -f "$video" && \
        mv -f "${video%.*}.hvc1.mp4" "${video%.*}.mp4" && \
        result="${result}, replaced the original." || \
        result="${result}, failed replacing the original."
      else
        rm -i "$video" && \
        mv -n "${video%.*}.hvc1.mp4" "${video%.*}.mp4" && \
        result="${result}." || \
        result="${result}, failed renaming the original."
      fi
      if [[ $? == 0 ]]
      then echo $result
      else echo $result >&2
        if [[ $debug == true ]]; then return $?; fi
      fi
    else
      echo "Failed to convert $video to hvc1 format, temporary file ${video%.*}.hvc1.mp4 might remain." >&2
      if [[ $debug == true ]]; then return $?; else echo "Error code: $?" >&2; fi
    fi
  done
}
function to_jxl {
  local remove=true
  while getopts 'fn' opt
  do
    case "$opt" in
      f) remove=true;;
      n) remove=false;;
      \?) return;;
    esac
  done
  shift $((OPTIND - 1))

  # Note: jxl animation is not natively supported by Apple, so -e gif -e png are excluded.
  # Also gif and png are potentially lossy when transcoded, more research is needed.
  # Other formats are rare and were not yet properly tested: -e exr -e ppm -e pfm -e pgx .
  if [[ $remove == true ]]
  then fd -e jpg -e jpeg --search-path="${@:-.}" -x echo \; -x cjxl --effort=9 --brotli_effort=11 --lossless_jpeg=1 {} {.}.jxl \; -x touch -r {} {.}.jxl \; -x rm
  else fd -e jpg -e jpeg --search-path="${@:-.}" -x echo \; -x cjxl --effort=9 --brotli_effort=11 --lossless_jpeg=1 {} {.}.jxl \; -x touch -r {} {.}.jxl
  fi
}
