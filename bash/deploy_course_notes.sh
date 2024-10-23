#!/bin/bash
#' ---
#' title: Deploy Course Notes
#' date:  20241018
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of course notes document
#'
#' ## Description
#' Deploy output of rendered course notes document to a website directory
#'
#' ## Details
#' This involves copying the rendered output, renaming the output if necessary and cleaning up
#'
#' ## Example
#' ./deploy_course_notes.sh -b <book_name> -s <cn_source_dir> -t <deploy_target>
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
  echo "Usage:   $SCRIPT -d <deploy_date> -h -l <link_title> -s <cn_source_path> "
  echo '                 -t <deploy_target_path> -z'
  echo '  where '
  echo '        -d <deploy_date>     --  (optional) alternative deploy date ...'
  echo '                                            > default: $(date +"%Y-%m-%d") ...'
  echo '        -h                   --  (optional) show usage message ...'
  echo '        -l <link_title>      --             link name ...'
  echo '        -s <cn_source_path>  --             course notes source path ...'
  echo '        -t <target_path>     --             deployment target path ...'
  echo '        -z                   --  (optional) produce verbose output ...'
  echo '                                            > default: false ...'
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

#' ### Write Entry To Data Table
#' Entry for table on website is written to data table
#+ write-data-table-entry-fun
write_data_table_entry () {
  local l_TBL_ENTRY="${DEPLOY_DATE};${LINK_TITLE};$(basename $TRG_PATH)"
  if [[ $VERBOSE == 'true' ]];then log_msg write_data_table_entry " * Cn table entry: $l_TBL_ENTRY ...";fi
  # check whether entry exists
  if [[ $(grep "$l_TBL_ENTRY" $CN_TABLE_DAT | wc -l ) -eq 0 ]];then
    echo "$l_TBL_ENTRY" >> $CN_TABLE_DAT
  else
    log_msg write_data_table_entry " * FOUND $l_TBL_ENTRY in $CN_TABLE_DAT ..."
  fi
}



#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
SRC_PATH=''
TRG_PATH=''
DEPLOY_DATE=''
LINK_TITLE=''
CN_TABLE_DAT=''
VERBOSE='false'
while getopts ":d:hl:s:t:z" FLAG; do
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
      if [[ -f $OPTARG ]];then
        SRC_PATH=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND source path: $OPTARG ..."
      fi
      ;;
    t)
      TRG_PATH=$OPTARG
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
if [[ $SRC_PATH == '' ]];then
  usage " *** ERROR: -s <source_path> required, but not defined ..."
fi
if [[ $TRG_PATH == '' ]];then
  usage " *** ERROR: -t <trg_path> required, but not defined ..."
fi
if [[ $LINK_TITLE == '' ]];then
  usage " *** ERROR: -l <link_title> required, but not defined ..."
fi
if [[ $DEPLOY_DATE == '' ]];then
  DEPLOY_DATE=$(date +"%Y-%m-%d")
fi
if [[ $CN_TABLE_DAT == '' ]];then
  CN_TABLE_DAT=$EVALREPO/inst/website/lbgfs2024/course_notes/course_notes.dat
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check args and defaults ..."
  log_msg $SCRIPT " * ==>  SRC_PATH:     $SRC_PATH ..."
  log_msg $SCRIPT " * ==>  TRG_PATH:     $TRG_PATH ..."
  log_msg $SCRIPT " * ==>  LINK_TITLE:   $LINK_TITLE ..."
  log_msg $SCRIPT " * ==>  DEPLOY_DATE:  $DEPLOY_DATE ..."
fi


#' ## Move From Source To Target
#' The source files after building is moved to the target path
#+ move-src-trg
log_msg $SCRIPT " * Deploy source to target"
if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Move $SRC_PATH to $TRG_PATH ...";fi
cp $SRC_PATH $TRG_PATH


#' ## Edit Deployed Results
#' Result is edited after deployment
#+ edit-deploy-results
log_msg $SCRIPT " * Edit deployed results ..."
open $TRG_PATH


#' ## Entry To Data Table
#' An entry to the data table of the website is written
#+ entry-to-data-table
log_msg $SCRIPT " * Edit deployed results ..."
write_data_table_entry



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

