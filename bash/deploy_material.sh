#!/bin/bash
#' ---
#' title: Deploy Material
#' date:  20241108
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of rendered output material and subsequent cleanup
#'
#' ## Description
#' Generic script to deploy rendered output to website target directories and afterwards cleaning up of output material
#'
#' ## Details
#' This script is rather generic and is best called by specific wrapper scripts
#'
#' ## Example
#' ./deploy_material.sh -d <deploy_date> -l <link_text> -s <src_dir> -t <target_deploy_dir> -w <data_table_path> 
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
  echo "Usage:   $SCRIPT -d <deploy_date> -h -l <link_text> -s <src_mat> -t <target_deploy_dir> -w <data_table_path> -z"
  echo '  where '
  echo '        -d <deploy_date>       --  (optional) alternative deployment date ...'
  echo '                                              > default: today ...'
  echo '        -h                     --  (optional) show usage message ...'
  echo '        -l <link_text>         --             text shown on website ...'
  echo '        -s <src_mat>           --             material consisting of files or directories to be deployed ...'
  echo '        -t <target_deploy_dir> --             target directory for deployment ...'
  echo '        -w <data_table_path>   --             path to data table file ...'
  echo '        -z                     --  (optional) produce verbose output'
  echo '                                              > default: false'
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

#' ### Move Material
#' Specified material is moved from source to target
#+ mv-mat-src-trg-fun
move_mat_from_src_to_trg () {
  for m in $SRC_MAT;do
    if [[ $VERBOSE == 'true' ]];then log_msg move_mat_from_src_to_trg " * Move $m to $TRG_DPL_DIR ..."
    mv $m $TRG_DPL_DIR
  done
}


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
SRC_MAT=''
SRC_CP_FILE=''
TRG_DPL_DIR=''
DEPLOY_DATE=''
LINK_TITLE=''
DATA_TABLE_PATH=''
VERBOSE='false'
while getopts ":d:hl:s:w:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DEPLOY_DATE=$OPTARG
      ;;
    l)
      LINK_TITLE=$OPTARG
      ;;
    s)
      if [[ -d $OPTARG ]] || [[ -f $OPTARG ]];then
        SRC_MAT=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND source material to be deployed at: $OPTARG ..."
      fi
      ;;
    t)
      TRG_DPL_DIR=$OPTARG
      ;;
    w)
      DATA_TABLE_PATH=$OPTARG
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
if [[ $SRC_MAT == '' ]] ;then
  usage " *** ERROR: -s <source_mat> required but not defined ..."
fi
if [[ $LINK_TITLE == '' ]];then
  usage " *** ERROR: -l <link_title> required, but not defined ..."
fi
if [[ $DATA_TABLE_PATH == '' ]];then
  usage " *** ERROR: -w <data_table_path> required, but not defined ..."
fi
if [[ $TRG_DPL_DIR == '' ]];then
  usage " *** ERROR: -t <target_deploy_dir> required, but not defined ..."
fi
# create target, if it does not yet exist
if [[ ! -d $TRG_DPL_DIR ]];then
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Create dir: $TRG_DPL_DIR ...";fi
  mkdir -p $TRG_DPL_DIR
fi
# default for deploy date. is today
if [[ $DEPLOY_DATE == '' ]];then
  DEPLOY_DATE=$(date +"%Y-%m-%d")
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check args and defaults ..."
  log_msg $SCRIPT " * ==>  SRC_MAT:          $SRC_MAT ..."
  log_msg $SCRIPT " * ==>  SRC_CP_FILE:      $SRC_CP_FILE ..."
  log_msg $SCRIPT " * ==>  TRG_DPL_DIR:      $TRG_DPL_DIR ..."
  log_msg $SCRIPT " * ==>  LINK_TITLE:       $LINK_TITLE ..."
  log_msg $SCRIPT " * ==>  DEPLOY_DATE:      $DEPLOY_DATE ..."
  log_msg $SCRIPT " * ==>  DATA_TABLE_PATH:  $DATA_TABLE_PATH ..."
fi


#' ## Move Material from Source To Target
#' Material specified is moved from source to target
#+ move-src-to_trg
log_msg $SCRIPT " * Move material ..."
move_mat_from_src_to_trg



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

