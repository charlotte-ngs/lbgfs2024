#!/bin/bash
#' ---
#' title: Deploy Solutions
#' date:  20241110
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of solution documents
#'
#' ## Description
#' Render and deploy solutions for exercises
#'
#' ## Details
#' This script renders the solutions document and copies the created material to the web-directories
#'
#' ## Example
#' ./deploy_solution.sh -e <exercise_name> -l <link_text>
#' SOLEXNAMES=$(ls -1 inst/exercises/lbgfs2024/solutions | tr '\n' ' ');for s in $SOLEXNAMES;do echo " * Sol: $s ...";./bash/deploy_solution.sh -e $s;sleep 2;done
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
  echo "Usage:   $SCRIPT -d <deploy_date> -e <exercise_name> -h -l <link_title> -q <quarto_yml>"
  echo '                 -s <source_solution_dir> -t <deployment_target_dir> -w <data_table_path> -z'
  echo '  where '
  echo '        -d <deploy_date>            --  (optional) alternative deploy date ...'
  echo '                                                   > default: $(date +"%Y-%m-%d") ...'
  echo '        -e <exercise_name>          --             exercise name ...'
  echo '        -h                          --  (optional) show usage message ...'
  echo '        -l <link_title>             --             link name, if not specified no data table is written ...'
  echo '                                                   > default: none'
  echo '        -q <quarto_yml>             --  (optional) quarto yml parameter file ...'
  echo '                                                   > default: _quarto.yml ...'
  echo '        -s <source_solution_dir>    --             source directory from where exercise is to be deployed ...'
  echo '        -t <deployment_target_dir>  --  (optional) target deployment directory ...'
  echo '                                                   > default: docs/exercise ...'
  echo '        -w <data_table_path>        --  (optional) alternative path to data table file ...'
  echo '                                                   > default: $EVALREPO/inst/website/lbgfs2024/exercises/exercises.dat ...'
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

#' ### Clean Up
#' Un-needed exercise material not needed after deployment
#' can be deleted
#+ clean-up-exc-material-fun
clean_up_exc_material () {
  local l_EXC_FILES_DIR=$SRC_SOL_DIR/${EXC_NAME}_files
  local l_EXC_HTML=$SRC_SOL_DIR/${EXC_NAME}.html
  local l_QMD_TRG=$TRG_DPL_DIR/$EXC_NAME/${EXC_NAME}.qmd
  for f in $l_EXC_FILES_DIR $l_EXC_HTML $l_QMD_TRG;do
    if [[ $VERBOSE == 'true' ]];then log_msg clean_up_exc_material " * Clean up for $f ...";fi
    if [[ -d $f ]] || [[ -f $f ]];then
      if [[ $VERBOSE == 'true' ]];then log_msg clean_up_exc_material " * Remove $f ...";fi
      rm -rf $f
    fi
  done
  
}

#' ### Data Table Entry
#' Data table entry which defines list of topics in website
#+ write-data-table-entry-fun
write_data_table_entry () {
  local l_TBL_ENTRY="${DEPLOY_DATE};${LINK_TITLE};$EXC_NAME"
  if [[ $VERBOSE == 'true' ]];then log_msg write_data_table_entry " * Cn table entry: $l_TBL_ENTRY ...";fi
  # check whether entry exists
  if [[ $(grep "$l_TBL_ENTRY" $DATA_TABLE_PATH | wc -l ) -eq 0 ]];then
    echo "$l_TBL_ENTRY" >> $DATA_TABLE_PATH
  else
    log_msg write_data_table_entry " * FOUND $l_TBL_ENTRY in $DATA_TABLE_PATH ..."
  fi
}



#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
EXC_NAME=''
SRC_SOL_DIR=''
TRG_DPL_DIR=''
DEPLOY_DATE=''
LINK_TITLE=''
DATA_TABLE_PATH=''
QYMLPAR=''
VERBOSE='false'
while getopts ":d:e:hl:q:s:t:w:z" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DEPLOY_DATE=$OPTARG
      ;;
    e)
      EXC_NAME=$OPTARG
      ;;
    l)
      LINK_TITLE=$OPTARG
      ;;
    q)
      if [[ -f $OPTARG ]];then
        QYMLPAR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND quarto-yml par at: $OPTARG ..."
      fi
      ;;
    s)
      if [[ -d $OPTARG ]];then
        SRC_SOL_DIR=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND source exercise dir: $OPTARG ..."
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
if [[ $SRC_SOL_DIR == '' ]];then
  if [[ $EXC_NAME == '' ]];then
    usage " *** ERROR: -s <source_solution_dir> or -e <exercise_name> required but not defined ..."
  else
    SRC_SOL_DIR=$EVALREPO/inst/exercises/lbgfs2024/solutions/$EXC_NAME
  fi
else
  EXC_NAME=$(basename $SRC_SOL_DIR)
fi
if [[ $LINK_TITLE == '' ]];then
  log_msg $SCRIPT " *** WARNING: -l <link_title> not defined ==> no data table written ..."
fi
if [[ $TRG_DPL_DIR == '' ]];then
  TRG_DPL_DIR=$EVALREPO/docs/solutions
fi
# create target, if it does not yet exist
if [[ ! -d $TRG_DPL_DIR ]];then
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Create dir: $TRG_DPL_DIR ...";fi
  mkdir -p $TRG_DPL_DIR
fi
if [[ $DEPLOY_DATE == '' ]];then
  DEPLOY_DATE=$(date +"%Y-%m-%d")
fi
if [[ $DATA_TABLE_PATH == '' ]];then
  DATA_TABLE_PATH=$EVALREPO/inst/website/lbgfs2024/solutions/solutions.dat
fi
if [[ $QYMLPAR == '' ]];then
  QYMLPAR=$EVALREPO/inst/exercises/lbgfs2024/_quarto.yml
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check args and defaults ..."
  log_msg $SCRIPT " * ==>  SRC_SOL_DIR:      $SRC_SOL_DIR ..."
  log_msg $SCRIPT " * ==>  EXC_NAME:         $EXC_NAME ..."
  log_msg $SCRIPT " * ==>  TRG_DPL_DIR:      $TRG_DPL_DIR ..."
  log_msg $SCRIPT " * ==>  LINK_TITLE:       $LINK_TITLE ..."
  log_msg $SCRIPT " * ==>  DEPLOY_DATE:      $DEPLOY_DATE ..."
  log_msg $SCRIPT " * ==>  DATA_TABLE_PATH:  $DATA_TABLE_PATH ..."
  log_msg $SCRIPT " * ==>  QYMLPAR:          $QYMLPAR ..."
fi


#' ## Render and Preview
#' Render the quarto source document and give a preview
#+ render-preview
quarto render $SRC_SOL_DIR/${EXC_NAME}.qmd --execute-params $QYMLPAR 


#' ## Delete Existing Target Dir
#' If target directory already exists, delete it
#+ del-trg-dir
TRG_DIR=$TRG_DPL_DIR/$EXC_NAME
if [[ -d $TRG_DIR ]];then
  log_msg $SCRIPT " * Delete existing target dir ..."
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Delete $TRG_DIR ...";fi
  rm -rf $TRG_DIR
fi


#' ## Copy Exercise Material
#' Copy material from source to target
#+ copy-material
log_msg $SCRIPT " * Copy material ..."
if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Copy $SRC_SOL_DIR to $TRG_DPL_DIR ...";fi
cp -r $SRC_SOL_DIR $TRG_DPL_DIR


#' ## Clean Up
#' Files and directories not needed any more are deleted
#+ clean-up
log_msg $SCRIPT " * Clean up exercise material ..."
clean_up_exc_material


#' ## Data Table Entry
#' The deployed exercise needs an entry in the exercise data table
#+ add-data-table-entry
if [[ $LINK_TITLE != '' ]];then
  log_msg $SCRIPT " * Write data table entry ..."
  write_data_table_entry
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

