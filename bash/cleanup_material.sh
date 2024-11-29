#!/bin/bash
#' ---
#' title: Cleanup Material
#' date:  20241108
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless cleaning up of output material
#'
#' ## Description
#' Clean up material consisting of output directories or files produced by rendering some source files
#'
#' ## Details
#' This is a generic script that removes specified directories or files. This is best called by specific wrapper scripts
#'
#' ## Example
#' ./cleanup_material.sh -d <cleanup_directories> -f <cleanup_files>
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
  echo "Usage:   $SCRIPT -d <cleanup_directories> -f <cleanup_files> -h -z"
  echo '  where '
  echo '        -d <cleanup_directories> --  list of directories to be cleaned up as space separated list ...'
  echo '        -f <cleanup_files>       --  list of files to be cleaned up as space separated list ...'
  echo '        -h                       --  (optional) show usage message ...'
  echo '        -z                       --  (optional) produce verbose output'
  echo '                                                > default: false'
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

#' ### Cleanup Directories
#' Given list of directories is removed
#+ cleanup-dirs-fun
cleanup_dirs () {
  for d in $CLEANUPDIRS;do
    if [[ $VERBOSE == 'true' ]];then log_msg cleanup_dirs " * Checking dir: $d ...";fi
    if [[ -d $d ]];then
      if [[ $VERBOSE == 'true' ]];then log_msg cleanup_dirs " * Delete dir: $d ...";fi
      rm -rf $d
    fi
  done
}

#' ### Cleanup Files
#' Given list of files are deleted
#+ cleanup-files-fun
cleanup_files () {
  for f in $CLEANUPFILES;do
    if [[ $VERBOSE == 'true' ]];then log_msg cleanup_files " * Checking file: $f ...";fi
    if [[ -f $f ]];then
      if [[ $VERBOSE == 'true' ]];then log_msg cleanup_files " * Delete file: $f ...";fi
      rm $f
    fi
  done
}


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
CLEANUPDIRS=''
CLEANUPFILES=''
VERBOSE='false'
while getopts ":d:f:hz" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      CLEANUPDIRS=$OPTARG
      ;;
    f)
      CLEANUPFILES=$OPTARG
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
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Checked arguments and set defaults: "
  log_msg $SCRIPT "   ==> CLEANUPDIRS: $CLEANUPDIRS ..."
  log_msg $SCRIPT "   ==> CLEANUPFILES: $CLEANUPFILES ..."
fi


#' ## Clean Up Directories
#' Cleaning up specified directories
#+ cleanup-dirs
if [[ $CLEANUPDIRS != '' ]];then
  log_msg $SCRIPT " * Cleanup dirs ..."
  cleanup_dirs
fi

#' ## Clean Up Files
#' Cleaning up specified files
#+ cleanup-files
if [[ $CLEANUPFILES != '' ]];then
  log_msg $SCRIPT " * Cleanup files ..."
  cleanup_files
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

