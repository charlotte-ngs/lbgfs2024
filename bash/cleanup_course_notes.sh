#!/bin/bash
#' ---
#' title: Clean Up Course Notes Build Results
#' date:  20241023
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless cleanup of build results
#'
#' ## Description
#' Clean up results of previous course notes building process
#'
#' ## Details
#' Deletion of output directories and files
#'
#' ## Example
#' ./cleanup_course_notes -s <source_dir>
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
  echo "Usage:   $SCRIPT -h -s <course_notes_source_dir> -z"
  echo '  where '
  echo '        -h  --  (optional) show usage message ...'
  echo '        -s                 source directory for course notes ...'
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


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
CN_SRC_DIR=''
BOOK_SUB_DIR=''
BOOK_NAME=''
VERBOSE='false'
while getopts ":hs:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    s)
      if [[ -d $OPTARG ]];then
        CN_SRC_DIR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND: course notes source dir at: $OPTARG ..."
      fi
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
if [[ $CN_SRC_DIR == '' ]];then
  usage " *** ERROR: -s <cn_source_dir> required, but not defined ..."
fi
if [[ $BOOK_SUB_DIR == '' ]];then
  BOOK_SUB_DIR=_book
fi
if [[ $BOOK_NAME == '' ]];then
  BOOK_NAME=$(grep 'book_filename' $EVALREPO/inst/cn/_bookdown.yml | cut -d ' ' -f2)
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Checked args and defaults: "
  log_msg $SCRIPT "   ==> CN_SRC_DIR:    $CN_SRC_DIR ..."
  log_msg $SCRIPT "   ==> BOOK_SUB_DIR:  $BOOK_SUB_DIR ..."
  log_msg $SCRIPT "   ==> BOOK_NAME:     $BOOK_NAME ..."
fi


#' ## Delete Results
#' Build results are deleted
#+ delete-results
log_msg $SCRIPT " * Delete items ..."
for i in $CN_SRC_DIR/$BOOK_SUB_DIR $CN_SRC_DIR/${BOOK_NAME}_files $CN_SRC_DIR/${BOOK_NAME}.log;do
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Currently deleting item: $i ...";fi
  rm -rf $i
done



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

