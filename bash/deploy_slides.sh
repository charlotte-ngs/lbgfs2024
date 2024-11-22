#!/bin/bash
#' ---
#' title: Deploy Slides
#' date:  20241122
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of rendered slides document
#'
#' ## Description
#' Deploy rendered pdf of slide document and add entry to web-dat file
#'
#' ## Details
#' Follow the same set up as other deploy scripts
#'
#' ## Example
#' ./deploy_slides.sh -d <deploy_date> -l <link_text> -s <source_path> -t <target_directory> -w <web_dat_path>
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
  echo "Usage:   $SCRIPT -d <deploy_date> -l <link_text> -s <source_path> -t <target_directory> -w <web_dat_path> -h -z"
  echo '  where '
  echo '        -d <deploy_date>     --  (optional) alternative deploy date ...'
  echo '                                            > default: $(date +"%Y-%m-%d") ...'
  echo '        -h                   --  (optional) show usage message ...'
  echo '        -l <link_title>      --             link name ...'
  echo '        -s <sl_source_path>  --             course notes source path ...'
  echo '        -t <target_dir>      --             deployment target path ...'
  echo '        -w <data_table_dat>  --  (optional) alternative path to course notes data table file ...'
  echo '                                            > default: $EVALREPO/inst/website/lbgfs2024/slides/slides.dat ...'
  echo '        -z                   --  (optional) produce verbose output'
  echo '                                            > default: false'
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
  local l_TBL_ENTRY="${DEPLOY_DATE};${LINK_TITLE};$(basename $SRC_PATH)"
  if [[ $VERBOSE == 'true' ]];then log_msg write_data_table_entry " * Cn table entry: $l_TBL_ENTRY ...";fi
  # check whether entry exists
  if [[ $(grep "$l_TBL_ENTRY" $DATA_TABLE_DAT | wc -l ) -eq 0 ]];then
    echo "$l_TBL_ENTRY" >> $DATA_TABLE_DAT
  else
    log_msg write_data_table_entry " * FOUND $l_TBL_ENTRY in $DATA_TABLE_DAT ..."
  fi
}

write_to_gitignore () {
  local l_SRC_DIR=$(dirname $SRC_PATH)
  local l_ODG_DIR=$l_SRC_DIR/odg
  if [[ $VERBOSE == 'true' ]];then log_msg write_to_gitignore " * Check for odg-dir: $l_ODG_DIR ...";fi
  if [[ -d $l_ODG_DIR ]];then
    if [[ $VERBOSE == 'true' ]];then log_msg write_to_gitignore " * Write $l_ODG_DIR/*.{pdf,png} ...";fi
    echo "$l_ODG_DIR/*.pdf" >> .gitignore
    echo "$l_ODG_DIR/*.png" >> .gitignore
  fi
}


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
SRC_PATH=''
TRG_DIR=''
DEPLOY_DATE=''
LINK_TITLE=''
DATA_TABLE_DAT=''
VERBOSE='false'
while getopts ":d:hl:s:t:w:z" FLAG; do
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
      TRG_DIR=$OPTARG
      ;;
    w)
      DATA_TABLE_DAT=$OPTARG
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
if [[ $TRG_DIR == '' ]];then
  TRG_DIR=$EVALREPO/docs/slides
fi
if [[ $LINK_TITLE == '' ]];then
  usage " *** ERROR: -l <link_title> required, but not defined ..."
fi
if [[ $DEPLOY_DATE == '' ]];then
  DEPLOY_DATE=$(date +"%Y-%m-%d")
fi
if [[ $DATA_TABLE_DAT == '' ]];then
  DATA_TABLE_DAT=$EVALREPO/inst/website/lbgfs2024/slides/slides.dat
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check args and defaults ..."
  log_msg $SCRIPT " * ==>  SRC_PATH:        $SRC_PATH ..."
  log_msg $SCRIPT " * ==>  TRG_DIR:        $TRG_DIR ..."
  log_msg $SCRIPT " * ==>  LINK_TITLE:      $LINK_TITLE ..."
  log_msg $SCRIPT " * ==>  DEPLOY_DATE:     $DEPLOY_DATE ..."
  log_msg $SCRIPT " * ==>  DATA_TABLE_DAT:  $DATA_TABLE_DAT ..."
fi


#' ## Move From Source To Target
#' The source files after building is moved to the target path
#+ move-src-trg
log_msg $SCRIPT " * Deploy source to target"
if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Move $SRC_PATH to $TRG_DIR ...";fi
cp $SRC_PATH $TRG_DIR


#' ## Entry To Data Table
#' An entry to the data table of the website is written
#+ entry-to-data-table
log_msg $SCRIPT " * Write data table entry ..."
write_data_table_entry


#' ## Entry To .gitignore
#' Write entry to .gitignore of pdf and png of included odg diagrams
#+ write-to-gitignore
log_msg $SCRIPT " * Write to .gitignore ..."
write_to_gitignore

#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

