#!/bin/bash 



# Debug Stuff #####
#script_debug=OFF 
script_debug=ON

# ON or OFF # FIXME Hab "bats" nicht mit den Farben dazu bekommen den Output zu vergleichen.
#script_color=OFF 
script_color=ON

if [ -n "$MTM_TESTSWITCH" ]; then
  script_debug=OFF 
  script_color=OFF   
fi


debugme() {
 [[ $script_debug = ON ]] && "$@" || :
 # be sure to append || : or || true here or use return 0, since the return code
 # of this function should always be 0 to not influence anything else with an unwanted
 # "false" return code (for example the script's exit code if this function is used
 # as the very last command in the script)
 # https://wiki.bash-hackers.org/scripting/debuggingtips#debugging_commands_depending_on_a_set_variable
}
debugme #set -vx #TODO an oder aus? #https://wiki.bash-hackers.org/scripting/debuggingtips#inject_debugging_code
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }' # https://wiki.bash-hackers.org/scripting/debuggingtips#making_xtrace_more_useful



# Variablen #####
script=$0
script_command="$(basename $script)"
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # TODO make Symlink Save? # https://stackoverflow.com/a/246128
script_name="MineTestManager (mtm)"
script_author="65194270+ShihanAlma@users.noreply.github.com"
script_version="0.0.1-dev"
script_needed_commands="echo dirname basename hash shopt mkdir wget curl unzip git read"
#script_needed_commands="foo" # for testing only

mtm_commands="list|check|setup|run"
mtm_command="$1"
mtm_run_path="$(pwd)"
mtm_rootdir="$(dirname "$script_directory")" # TODO Variante bauen die auch nicht relativ funktioniert
mtm_tempdir="$mtm_rootdir/.mtm_tmp"
mtm_instance_name="$2"
mtm_instance_path="$mtm_rootdir/$mtm_instance_name"
mtm_instance_bin="$mtm_instance_path"/bin/minetest.exe
mtm_instance_modsdir="$mtm_instance_path"/mods/
mtm_instance_config="$3"

if [ "$script_color" = "ON" ]; then
  color="\e[34m"
  roloc="\e[0m"
else
  color=""
  roloc=""
fi



# Functions #####
echome() {
  echo -e "$script_command: $*"
}
errorme() {
  echo -e "$script_command: $*" >&2
}

# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c#gistcomment-3294173
lastversionurl() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | grep -o "http.*${3:-win64.zip}"
}

# Main #####
debugme echome "$script from $script_directory"
echome "$script_name v$script_version by $script_author"
echo


# check for commands
missing_counter=0
for needed_command in $script_needed_commands; do
  if ! hash "$needed_command" >/dev/null 2>&1; then
    errorme "Command not found in PATH: $color$needed_command$roloc"
    ((missing_counter++))
    # ToDo evtl. installationshilfe ausgeben? Bei Ubuntu scheint es zu reichen, wenn man das Command aufruft
  fi
done
if ((missing_counter > 0)); then
  errorme "Minimum $color$missing_counter$roloc commands are missing in PATH, aborting"
  exit 1
fi


# LIST instances
if [ -z "$mtm_command" ] || [ "$mtm_command" = "list" ]; then
  # https://stackoverflow.com/a/18887210
  shopt -s nullglob
  array=(*/)
  shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

  if (( ${#array[@]} == 0 )); then
    echome "No instances yet in $mtm_rootdir"
    echo
    echome "To create an instances use"
    echo "$script setup [instance_name]"
  else
    echome "Instances in $mtm_rootdir:"
    printf '%s\n' "${array[@]%"/"}"
    echo
    echome "To check an instance use"
    echo "$script check [instance_name]"
  fi

  exit 0
fi


# unknown command
if ! [[ "$mtm_command" =~ ^($mtm_commands)$ ]]; then
  echome "unknown command $color$mtm_command$roloc."
  echo
  echome "To list all instances use"
  echo "$script [list]"
  exit 0
fi


# dont use .mtm dirs # ToDo add .mtm-test und .mtm_tmp. oder gleich auf . am Anfang checken?
if [ "$mtm_instance_path" = "$script_directory" ]; then
  errorme "$color$mtm_instance_name$roloc is the MintestManger Script directory! Don't use it as instance!"
  echo
  echome "To list all instances use"
  echo "$script [list]"
  exit 1
fi


# check, setup, run
echome "check for instance named $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc ..."
if [ ! -d "$mtm_instance_path" ]; then
  echome "No instance named $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc!"
  case "$mtm_command" in
    check)
      echo
      echome "To list all instances use"
      echo "$script [list]"
      exit 10
    ;;
    setup)
      echome "Create instance dir $color$mtm_instance_path$roloc!"
      mkdir "$mtm_instance_path"
    ;;
  esac
else
  echome "Found instance named $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc!"
fi

echome "check for Minetest in instance $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc ..."
if [ ! -f "$mtm_instance_bin" ]; then # ToDo er geht garnicht rein wenn es da ist. prüft daher auch nicht die version!
  echome "No Minetest Binary in instance $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc!"
  case "$mtm_command" in
    check)
      echo
      echome "To setup an instances use"
      echo "$script setup [instance_name]"
      exit 10
    ;;
    setup)
      echome "Download Minetest latest version to $color$mtm_tempdir$roloc ..."
      mt_last=$(lastversionurl "minetest/minetest")
      wget -N -P "$mtm_tempdir" "$mt_last"
      mt_last_file=$(basename "$mt_last")
      mt_last_dir=$(basename "$mt_last" .zip)
      echome "unzip $color$mtm_tempdir/$mt_last_file$roloc to $color$mtm_tempdir$roloc ..."
      unzip -u "$mtm_tempdir/$mt_last_file" -d "$mtm_tempdir"
      echome "copy to instance $color$mtm_tempdir/$mt_last_dir$roloc to $color$mtm_instance_path$roloc ..."
      cp -ru "$mtm_tempdir/$mt_last_dir/"* "$mtm_instance_path/"
    ;;
  esac
else
  echome "Found Mintest in instance $color$mtm_instance_name$roloc in $color$mtm_rootdir$roloc!"
fi

# ModsDB
mtm_moddb_path="$script_directory"/mtm-modsdb.csv
declare -A mtm_moddb_urls
declare -A mtm_moddb_dependencies
[ ! -f "$mtm_moddb_path" ] && { echome "$mtm_moddb_path not found"; exit 1; }
echome "Read $color$mtm_moddb_path$roloc ..."
while IFS=, read -r mod_aktiv mod_name mod_desc mod_url mod_dep mod_more; do
  if [ -z "$mod_aktiv" ]; then
    debugme echome "$mod_name at $mod_url dependencies = $mod_dep"
    mtm_moddb_urls+=([$mod_name]="$mod_url")
    mtm_moddb_dependencies+=([$mod_name]="$mod_dep")
  fi
done < "$mtm_moddb_path"
echome "Read $color${#mtm_moddb_urls[@]}$roloc Mods from $color$mtm_moddb_path$roloc!"
debugme echome "${!mtm_moddb_urls[@]}"

declare -A mtm_modset
build_modset() {
  if [[ "${mtm_moddb_dependencies[$1]+foobar}" ]]; then
    mod_dep=${mtm_moddb_dependencies[$1]}
    if [[ "$1" != *:* ]]; then
      mod_url=${mtm_moddb_urls[$1]}
      mtm_modset+=([$1]="$mod_url")
      debugme echome "ModSet = ${!mtm_modset[@]}!"
    fi
    for item in ${mod_dep[@]}; do
      build_modset "$item"
    done
  else
    echome "No Entry for $color$1$roloc in $color$mtm_moddb_path$roloc!"
    exit 1
  fi
  
}
echome "Get ModSet for config $mtm_instance_config ..."
build_modset "$mtm_instance_config"

# Setup (update=rebase or install=clone) Mods
setup_mod() {
  local mtm_mod_name="$1"
  local mtm_mod_url="$2"

  echo "$mtm_mod_name"
  echo "$mtm_mod_url"

  # ToDo check noch einbauen (Dir nur prüfen und Änderung nur anzeigen)
  if [ -d "$mtm_mod_name" ]; then
    echo directory exists
  else
    mkdir "$mtm_mod_name"
  fi

  cd "$mtm_mod_name" || { echome "FATAL - can not cd to mod $mtm_mod_name"; exit 1; }
  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]; then
    git rebase
  else 
    # ToDo clone
    git clone $mtm_mod_url .
  fi
  cd .. || { echome "FATAL - can not cd back to mods dir $mtm_mod_name"; exit 1; }
}

echome "Setup Mods in $color$mtm_instance_modsdir$roloc ..."
cd "$mtm_instance_modsdir" || { echome "FATAL - can not cd to mods dir $mtm_instance_modsdir"; exit 1; }
for item in "${!mtm_modset[@]}"; do
  #echo "$item"
  setup_mod "$item" "${mtm_modset[$item]}"
done
cd "$mtm_run_path" || { echome "FATAL - can not cd back to $mtm_run_path"; exit 1; }


## TODO
# Commands
# ohne command = list
# check = prüfen
# setup = installieren, evtl. einen zielstand angeben?
## prüfen ob dir leer wenn kein mintest installiert
# kein upgrade = geht via setup, einfach den neuesten Stand ausrollen
# run = starten
