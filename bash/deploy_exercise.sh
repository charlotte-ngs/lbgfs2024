#!/bin/bash
#' ---
#' title: Deploy Exercise Material
#' date:  20241101
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of exercise material
#'
#' ## Description
#' Deploy an exercise folder to the web-space
#'
#' ## Details
#' This copies prepared sources and rendered output to the correct web-directory
#'
#' ## Example
#' ./deploy_exercise.sh -s <source_exercise_dir> -t <deployment_target_dir>
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
  echo "Usage:   $SCRIPT -h -s <source_exercise_dir> -t <deployment_target_dir> -z"
  echo '  where '
  echo '        -h                          --  (optional) show usage message ...'
  echo '        -s <source_exercise_dir>    --             source directory from where exercise is to be deployed ...'
  echo '        -t <deployment_target_dir>. --  (optional) target deployment directory ...'
  echo '                                                   > default: docs/exercise ...'
  echo '        -z                          --  (optional) produce verbose output'
  echo '                                                   > default: false'
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
SRC_EXC_DIR=''
TRG_DPL_DIR=''
VERBOSE='false'
while getopts ":hs:t:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    s)
      if [[ -d $OPTARG ]];then
        SRC_EXC_DIR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND source exercise dir: $OPTARG ..."
      fi
      ;;
    t)
      TRG_DPL_DIR=$OPTARG
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
if [[ $SRC_EXC_DIR == '' ]];then
  usage " *** ERROR: -s <source_exercise_dir> required but not defined ..."
fi
if [[ $TRG_DPL_DIR == '' ]];then
  TRG_DPL_DIR=$EVALREPO/docs/exercises
fi
# create target, if it does not yet exist
if [[ ! -d $TRG_DPL_DIR ]];then
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Create dir: $TRG_DPL_DIR ...";fi
  mkdir -p $TRG_DPL_DIR
fi


#' ## Copy Exercise Material
#' Copy material from source to target
#+ copy-material
log_msg $SCRIPT " * Copy material ..."
if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Copy $SRC_EXC_DIR to $TRG_DPL_DIR ...";fi
cp -r $SRC_EXC_DIR $TRG_DPL_DIR


#' ## Clean Up
#' Files and directories not needed any more are deleted
#+ clean-up
EXC_NAME=$(basename $SRC_EXC_DIR)
EXC_FILES_DIR=$SRC_EXC_DIR/${EXC_NAME}_files
EXC_HTML=$SRC_EXC_DIR/${EXC_NAME}.html
QMD_TRG=$TRG_DPL_DIR/$EXC_NAME/${EXC_NAME}.qmd
for f in $EXC_FILES_DIR $EXC_HTML $QMD_TRG;do
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Clean up for $f ...";fi
  if [[ -d $f ]] || [[ -f $f]];then
    if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Remove $f ...";fi
    rm -rf $f
  fi
done


#' ## Data Table Entry
#' The deployed exercise needs an entry in the exercise data table
#+ add-data-table-entry
 1074  cat inst/website/lbgfs2024/exercises/exercises.dat
 1075  echo '2024-11-01;Sire model;lbg_ex05' >> inst/website/lbgfs2024/exercises/exercises.dat 



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

