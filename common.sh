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
  echo docker run -v $(pwd)/phantom_render.js:/script.js -e URL=$1 --rm wernight/phantomjs phantomjs --ignore-ssl-errors=true /script.js
}