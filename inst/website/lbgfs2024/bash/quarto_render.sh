#!/bin/bash
#' ---
#' title: Render Quarto Source Files
#' date:  20240915
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless render of quarto source files
#'
#' ## Description
#' Render all quarto source files in a given evaluation directory
#'
#' ## Details
#' The directory in which the quarto source files can be found is set within the script relative to where the script is stored
#'
#' ## Example
#' ./quarto_render.sh
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails


#' ### Files and Directories
#' Global constants related to script name and directories which do not depend 
#' on any input from the commandline are defined in the following code block
#+ script-files, eval=FALSE
SERVER=$(hostname)                          # put hostname of server in variable      #
SCRIPT=$(basename ${BASH_SOURCE[0]})        # Set Script Name variable                #
SCRSTEM=$(echo $SCRIPT | sed -e "s/\.sh//")
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EVALREPO=$(dirname $SCRIPT_DIR)
EVALROOT=$(dirname $EVALREPO)
REAL_SCRIPT=$(readlink -f $SCRIPT_DIR/$SCRIPT)
REAL_SCRIPT_DIR=$(dirname $REAL_SCRIPT)
REAL_EVALREPO=$(dirname $REAL_SCRIPT_DIR)
REAL_EVALROOT=$(dirname $REAL_EVALREPO)
CURWD=$(pwd)


#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  echo "Message: $l_MSG"
  echo "Usage:   $SCRIPT -h -z"
  echo '  where '
  echo '        -h  --  (optional) show usage message ...'
  echo '        -z  --  (optional) produce verbose output'
  echo '                           > default: false'
  echo 
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
start_msg () {
  echo '********************************************************************************'
  echo "Starting $SCRIPT at: "`date +"%Y-%m-%d %H:%M:%S"`
  echo "Server:  $SERVER"
  echo
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  echo
  echo "End of $SCRIPT at: "`date +"%Y-%m-%d %H:%M:%S"`
  echo '********************************************************************************'
}

#' ### Log Message
#' Log messages formatted similarly to log4r are produced.
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`date +"%Y%m%d%H%M%S"`
  echo "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}

#' ### Directory Existance Check
#' Check whether directory exist, if not create it
#+ check-exist-create-dir-fun
check_exist_create_dir () {
  local l_CHECK_DIR=$1
  if [ ! -d "$l_CHECK_DIR" ]
  then
    log_msg check_exist_create_dir " * CANNOT FIND: $l_CHECK_DIR ==> create ..."
    mkdir -p $l_CHECK_DIR
  fi
}



#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
QUARTODOC=''
QSRCDIR=''
TRGDIR=''
QYMLPAR=''
VERBOSE='false'
while getopts ":d:hq:s:t:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      if [[ -f $OPTARG ]];then
        QUARTODOC=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND quarto-document: $OPTARG ..."
      fi
      ;;
    q)
      if [[ -f $OPTARG ]];then
        QYMLPAR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND quarto yml parfile: $OPTARG ..."
      fi
      ;;
    s)
      if [[ -d $OPTARG ]];then
        QSRCDIR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND quarto source directory: $OPTARG ..."
      fi
      ;;
    t)
      TRGDIR=$OPTARG
      ;;
    z)
      VERBOSE='true'
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg


#' ## Command Line Argument Checks and Setting of Defaults
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value or they are set to a 
#' meaningful default value
#+ argument-test, eval=FALSE
log_msg $SCRIPT " * Check arguments and set defaults ..."
if [[ $QSRCDIR == '' ]];then
  QSRCDIR=$EVALREPO
fi
if [[ $TRGDIR == '' ]];then
  TRGDIR=$QSRCDIR/_site
fi
check_exist_create_dir $TRGDIR
if [[ $QYMLPAR == '' ]];then
  QYMLPAR=$QSRCDIR/_quarto.yml
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Checked values and defaults ..."
  log_msg $SCRIPT " * *** QSRCDIR: $QSRCDIR ..."
  log_msg $SCRIPT " * *** TRGDIR:  $TRGDIR ..."
  log_msg $SCRIPT " * *** QYMLPAR: $QYMLPAR ..."
fi


#' ## Render Quarto Documents
#' Render quarto documents
#+ render-quarto-docs
log_msg $SCRIPT " * Render quarto documents ..."
if [[ $QUARTODOC == '' ]];then
  # change to source directory
  cd $QSRCDIR
  for f in $(find . -type f -name "*.qmd");do 
    if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Render $f ...";fi
    quarto render $f --execute-params $QYMLPAR --output-dir $TRGDIR
    sleep 2
  done
  # preview page
  quarto preview index.qmd --to html --no-watch-inputs --no-browse
  # back to working directory from before
  cd $CURWD
else
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Render $QUARTODOC ...";fi
  quarto render $QUARTODOC --execute-params $QYMLPAR --output-dir $TRGDIR
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

