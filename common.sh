# Common scripts. To be sourced.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Find the time command
GTIME=$(which time)
if which gtime 2> /dev/null; then
    GTIME=$(which gtime)
fi

# Run a command and profile it. The time it took is written to the variable $1. The command is the rest of the arguments.
prf() {
  VAR=$1
  shift
  echo "-----------------------------------"
  echo "Profiling $VAR"
  $GTIME -o $DIR/.rptprfout -f "%E" $@
  eval "${VAR}"="'$(cat $DIR/.rptprfout)'"
  rm $DIR/.rptprfout
}

access_page() {
  if [ -z "$2" ];
  then
    echo docker run                           -v $DIR/phantom_render.js:/script.js -e URL=$1 --rm wernight/phantomjs phantomjs --ignore-ssl-errors=true /script.js
  else
    NOPORT=$(echo $3 | cut -d: -f1)
    echo docker run --add-host "$NOPORT:$2" -v $DIR/phantom_render.js:/script.js -e URL=$1 --rm wernight/phantomjs phantomjs --ignore-ssl-errors=true /script.js
  fi
}