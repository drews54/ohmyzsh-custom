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
      c)
        if [[ -n "$OPTARG" ]]
        then
          case "$OPTARG" in
            x265|vtb) encoder="$OPTARG";;
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
  if   [[ $encoder == x265 ]]; then ffmpeg_params='-hide_banner -i "%s" -c:v libx265 -preset slow -tag:v hvc1 -map_metadata 0 "%s"'
  elif [[ $encoder == vtb ]];  then ffmpeg_params='-hide_banner -i "%s" hevc_videotoolbox -q:v 55 -tag:v hvc1 -map_metadata 0 "%s"'
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
# Compresses PDF files using GhostScript. Usage: compresspdf [input file] [output file] [screen*|ebook|printer|prepress]
function compresspdf {
    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -dPDFSETTINGS=/${3:-"screen"} -dCompatibilityLevel=1.4 -sOutputFile="$2" "$1"
}
# Finds media files in a tree below given directory that were modified on the current day and month of any year.
function find_today_files {
    today=$(date +%j)
    find ${@:-.} -type f \! -name .DS_Store -print0|\
      while IFS= read -r -d '' file
      do
        file_day=$(date -r "$file" +%j)
        if [[ "$file_day" == "$today" ]]
        then
          echo "'$file'"
        fi
      done
}
# Opens files found by the find_today_files function (see above).
function open_today_files {
  # find_today_files | tr '\n' '\0' | xargs -0 open
  find_today_files "$@" | xargs open
}
# Archives files found by the find_today_files function (see above).
function zip_today_files {
  local archive="$HOME/$(date +'%Y-%m-%d').zip"
  # find_today_files | tr '\n' '\0' | xargs -0 zip "$HOME/$(date +'%Y-%m-%d').zip"
  find_today_files "$@" | xargs zip -j "$archive" && echo "Exported to $archive" || echo "Exporting to $archive failed"
}
function reverse_args {
  for arg in "$@"
  do
    args=("$arg" "${args[@]}")
  done
  printf '%s ' "${args[@]}"
  printf '\n'
}
function to_heic {
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

  if [[ $remove == true ]]
  then fd -e jpg -e jpeg -e tif -e tiff -e png -e gif -e jp2 -e pict -e bmp -e qtif -e psd -e sgi -e tga -e webp --search-path="${@:-.}" -x sips -s format heic {} -o {.}.heic \; -x touch -r {} {.}.heic \; -x rm
  else fd -e jpg -e jpeg -e tif -e tiff -e png -e gif -e jp2 -e pict -e bmp -e qtif -e psd -e sgi -e tga -e webp --search-path="${@:-.}" -x sips -s format heic {} -o {.}.heic \; -x touch -r {} {.}.heic
  fi
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
function lsrf {
  setopt -x
  local open=false
  while getopts 'd:oa:' opt
  do
    case "$opt" in
      d) local depth=$OPTARG;;
      o) open=true;;
      a) local app=$OPTARG;;
      \?) return;;
    esac
  done
  shift $((OPTIND - 1))

  result=$(find ${1:-.} ${(z)depth:+-maxdepth $depth} -type f | sort -R | head -1)

  case "$open" in
    false) echo "$result";;
    true) open ${(z)app:+-a $app} "$result";;
  esac
}
