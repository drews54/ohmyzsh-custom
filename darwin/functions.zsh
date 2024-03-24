function is_hvc1 {
  typeset opt

  while getopts 'q' opt
  do
    case "$opt" in
      q) typeset quiet=true;;
      \?) return 1;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ $(ffprobe -v error -select_streams v:0 -show_entries stream=codec_tag_string -of default=noprint_wrappers=1:nokey=1 "$@" 2>&1) == hvc1 ]]
  then
    if [[ ! -v quiet ]]; then echo "$@ is in hvc1 format"; fi
    return 0
  else
    if [[ ! -v quiet ]]; then echo "$@ is not in hvc1 format"; fi
    return 1
  fi
}
function to_hvc1 {
  typeset opt
  local encoder=x265

  while getopts 'fdc:a' opt
  do
    case "$opt" in
      f) typeset force=true;;
      d) typeset debug=true;;
      c) if [[ -n "$OPTARG" ]]
         then
           case "$OPTARG" in
             x265|vtb) encoder="$OPTARG";;
             *) echo "$OPTARG is not a supported encoder" >&2
                if [[ -v debug ]]
                  then return 1
                  else echo "Using default encoder $encoder"
                fi;;
           esac
         fi;;
      a) typeset no_copy_audio=true;;
      \?) [[ -v debug ]] && return 1;;
    esac
  done

  shift $((OPTIND - 1))

  local ffmpeg_params
  if   [[ $encoder == x265 ]]; then ffmpeg_params='-hide_banner -i "%s" -c:v libx265 -preset slow -tag:v hvc1 -map_metadata 0 "%s"'
  elif [[ $encoder == vtb ]];  then ffmpeg_params='-hide_banner -i "%s" hevc_videotoolbox -q:v 55 -tag:v hvc1 -map_metadata 0 "%s"'
  else echo "Somehow $encoder got past validation to the converter..." >&2; return 1
  fi
  [[ ! -v no_copy_audio ]] && ffmpeg_params=$(echo $ffmpeg_params | sed 's/\("%s"\)\([^"%s"]*\)$/-c:a copy \1\2/')

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
      if [[ -v force ]]
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
        else echo $result >&2; [[ -v debug ]] && return $?
      fi
    else
      echo "Failed to convert $video to hvc1 format, temporary file ${video%.*}.hvc1.mp4 might remain." >&2
      if [[ -v debug ]]
        then return $?
        else echo "Error code: $?" >&2
      fi
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
  typeset opt
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
  typeset opt cmd

  while getopts 'ane:qv' opt
  do
    case $opt in
      a) typeset all_extensions=true;;
      n) typeset no_remove=true;;
      e) typeset extension=$OPTARG;;
      q) typeset quiet=true;;
      v) typeset verbose=true;;
      \?) return;;
    esac
  done
  shift $((OPTIND - 1))

  # Note: jxl animation is not natively supported by Apple, so -e gif -e png are excluded by default.
  # Also gif and png are potentially lossy when transcoded, more research is needed.
  # Other formats are rare and were not yet properly tested: -e exr -e ppm -e pfm -e pgx.
  cmd="fd "
  if [[ -v extension ]]
  then cmd+="-e $extension "
  else cmd+="-e jpg -e jpeg "
  fi
  if [[ -v all_extensions ]]
  then cmd+="-e jpg -e jpeg -e png -e apng -e gif -e exr -e ppm -e pfm -e pam -e pgx "
  fi
  cmd+="--search-path=${@:-.} "
  if [[ -v quiet ]]
  then cmd+="-x cjxl "
  else cmd+="-x echo '{/} -> {/.}.jxl' \; -x cjxl "
  fi
  if [[ ! -v verbose ]]
  then cmd+="--quiet "
  fi
  cmd+="--effort=9 --brotli_effort=11 --lossless_jpeg=1 {} {.}.jxl \; -x touch -r {} {.}.jxl "
  if [[ ! -v no_remove ]]
  then cmd+=" \; -x rm"
  fi
  eval $cmd
}
function lsrf {
  typeset opt
  while getopts '1lia:d:twe:qs:' opt
  do
    case "$opt" in
      1) typeset first_result=true;;
      l) typeset list=true;;
      i) typeset interactive=true;;
      a) typeset app=$OPTARG;;
      d) typeset depth=$OPTARG;;
      t) typeset recent=true;;
      w) typeset wait=true;;
      e) typeset extension=$OPTARG;;
      q) typeset quiet=true;;
      s) typeset search=$OPTARG;;
      \?) return 1;;
    esac
  done
  shift $((OPTIND - 1))

  if [[ -v recent ]]
  then result=("${(f)$(find ${@:-.} ${(z)depth:+-maxdepth $depth} -type f ${(z)search:+-iname *$search*} ${(z)extension:+-iname *.$extension} ! -name .DS_Store -exec ls -t {} +)}")
  else result=("${(f)$(find ${@:-.} ${(z)depth:+-maxdepth $depth} -type f ${(z)search:+-iname *$search*} ${(z)extension:+-iname *.$extension} ! -name .DS_Store | sort -R)}")
  fi

  if [[ -v first_result ]]
  then result=$result[1]
  fi

  if [[ -v list ]]
  then
    print -l $result
    return
  fi

  if [[ ! ( -v interactive || -v first_result ) ]]
  then
    [[ ! -v quiet ]] && print "Running in non-interactive mode. Use Ctrl+C to exit."
    if [[ ! ( -v wait || -v quiet ) ]]
    then
      if read -qs "?This will open all found files at once! Press Y to continue, any other key to abort"
      then print
      else print "\nOperation aborted." && return
      fi
    fi
  fi

  for i in $result
  do
    [[ ! -v quiet ]] && print "Opening '$i' using ${app:-default app}."
    if [[ -v wait ]]
    then
      setopt local_traps
      if [[ -v quiet ]]
      then trap 'return' INT
      else trap 'print "\e[2K\rOperation stopped."; return' INT
      fi
      open -W ${(z)app:+-a $app} $i
    else open ${(z)app:+-a $app} $i
    fi
    if [[ -v interactive ]]
    then if read -qs "?Press Y to stop, any other key to continue"
         then [[ ! -v quiet ]] && print "\nOperation stopped."; return
         else [[ ! -v quiet ]] && print
         fi
    fi
  done
  if [[ ! ( -v first_result || -v quiet ) ]]; then print "Files list exhausted."; fi
}
