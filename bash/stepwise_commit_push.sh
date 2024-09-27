#!/bin/bash
#' ---
#' title: Stepwise Commit and Push
#' date:  20240927
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless commit and push of large changes
#'
#' ## Description
#' Stepwise commit of changes and push to github of these small committed changes
#'
#' ## Details
#' Since github has lowered the maximum size of changes to be pushed, we sometimes need to commit and push changes including many files one file after an other
#'
#' ## Example
#' ./stepwise_commit_push.sh -s <source_path>
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


#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  echo "Message: $l_MSG"
  echo "Usage:   $SCRIPT -c <commit_path> -h -s <status_tag>  -z"
  echo '  where '
  echo '        -c <source_path>  --  (optional) alternative path which should be added as commit ...'
  echo '                                         > default: . '
  echo '        -h                --  (optional) show usage message ...'
  echo '        -s <status_tag>   --  (optional) alternative status tag ...'
  echo '                                         > default: new file '
  echo '        -z                --  (optional) produce verbose output'
  echo '                                         > default: false'
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


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
COMMIT_PATH=''
STATUS_TAG=''
VERBOSE='false'
while getopts ":c:hs:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    c)
      if [[ ! -d $OPTARG ]] || [[ ! -f $OPTARG ]];then
        COMMIT_PATH=$OPTARG
      else
        usage " * CANNOT FIND source path: $OPTARG ..."
      fi
      ;;
    s)
      STATUS_TAG=$OPTARG
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
if [[ $COMMIT_PATH == '' ]];then
  COMMIT_PATH='.'
fi
if [[ $STATUS_TAG == '' ]];then
  STATUS_TAG='new file'
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * *** COMMIT_PATH: $COMMIT_PATH ..."
  log_msg $SCRIPT " * *** STATUS_TAG:  $STATUS_TAG ..."
fi

#' ## Commit and Push Stepwise
#' 
#+ your-code-here
log_msg $SCRIPT " * Add changes and commit and push stepwise ..."
git add $COMMIT_PATH
FILE_COL=$(git status | grep "$STATUS_TAG" | head -1 | tr -s ' ' '\n' | wc -l)
for f in $(git status | grep "$STATUS_TAG" | tr -s ' ' ';' | cut -d ';' -f${FILE_COL});do
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * File: $f ...";fi
  git commit -m "Commit $f" $f
  git push origin main
  sleep 2
done


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

