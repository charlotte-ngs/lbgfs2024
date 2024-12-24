#!/bin/bash
#' ---
#' title: Deploy Quarto Slides
#' date:  20241220
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless render and deploy of quarto slides
#'
#' ## Description
#' Render and deploy quarto slides
#'
#' ## Details
#' Based on a quarto markdown (qmd) source document, render it and deploy the rendered output to a target directory
#'
#' ## Example
#' ./deploy_quarto_slides.sh -n <slides_name> -s <slides_source_path> -t <deploy_trg_dir>
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
  echo "Usage:   $SCRIPT -d <deploy_date> -h -l <link_title> -q <quarto_yml> "
  echo '                 -s <slides_name|slides_source_path> -t <deploy_trg_dir>'
  echo '                 -v -w <data_table_path> -z'
  echo '  where '
  echo '        -d <deploy_date>                      --  (optional) alternative deployment date ...'
  echo '                                                             > default: date +"%Y%d%m%H%M%S" ...'
  echo '        -h                                    --  (optional) show usage message ...'
  echo '        -l <link_title>                       --             link name ...'
  echo '        -q <quarto_yml>                       --  (optional) quarto yml parameter file ...'
  echo '                                                             > default: _quarto.yml ...'
  echo '        -s <slides_name|slides_source_path>   --             slides name or source path to slides ...'
  echo '        -t <deploy_trg_dir>                   --             deploy target directory ...'
  echo '        -v                                    --  (optional) run quarto preview on qmd ...'
  echo '                                                             > default: false ...'
  echo '        -w <data_table_path>                  --  (optional) alternative path to data table file ...'
  echo '                                                             > default: $EVALREPO/inst/website/lbgfs2024/slides/slides.dat ...'
  echo '        -z                                    --  (optional) produce verbose output'
  echo '                                                             > default: false ...'
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

#' ### Render and Preview
#' Render and preview the qmd source document
#+ render-and-preview
quarto_preview_render () {
if [[ $PREVIEW == 'true' ]];then
  log_msg quarto_preview_render " * Render and Preview ..."
  quarto preview $SRC_QSL_PATH --to revealjs --presentation --no-watch-inputs --no-browse
else
  log_msg quarto_preview_render " * Render document ..."
  if [[ -f $QYMLPAR ]];then
    quarto render $SRC_QSL_PATH --execute-params $QYMLPAR 
  else
    quarto render $SRC_QSL_PATH
  fi
fi
  
}

#' ### Deploy Material
#' Deploy the material to target directory
#+ deploy-material-fun
deploy_material () {
  # copy directories to target
  log_msg deploy_material " * Copy directories ..."
  for d in $COPYDIR;do
    if [[ $VERBOSE == 'true' ]];then log_msg deploy_material " * Copy $d to $TRG_DPL_DIR ...";fi
    cp -r $SRC_QSL_DIR/$d $TRG_DPL_DIR
  done
  # copy files
  log_msg deploy_material " * Move directories ..."
  for d in $MOVEDIR;do
    if [[ $VERBOSE == 'true' ]];then log_msg deploy_material " * Move $d to $TRG_DPL_DIR ...";fi
    if [[ -d $TRG_DPL_DIR/$d ]];then
      if [[ $VERBOSE == 'true' ]];then log_msg deploy_material " * Remove $TRG_DPL_DIR/$d ...";fi
      rm -rf $TRG_DPL_DIR/$d
    fi
    mv $SRC_QSL_DIR/$d $TRG_DPL_DIR
  done
  # move files
  log_msg deploy_material " * Move files ..."
  for f in $MOVEFILE;do
    if [[ $VERBOSE == 'true' ]];then log_msg deploy_material " * Move $f to $TRG_DPL_DIR ...";fi
    mv $SRC_QSL_DIR/$f $TRG_DPL_DIR
  done

}

#' ### Write Entry to Data Table
#' Write an entry to the data table
#+ write-data-table-entry-fun
write_data_table_entry () {
  # check whether previous entry exists
  local l_PRIM_KEY="${LINK_TITLE};${QSL_NAME}.html"
  local l_DATA_ENTRY="${DEPLOY_DATE};${l_PRIM_KEY}"
  # check whether identical entry exists
  if [[ $(grep "$l_DATA_ENTRY" $DATA_TABLE_PATH | wc -l) -gt 0 ]];then
    log_msg write_data_table_entry " * Found $l_DATA_ENTRY in $DATA_TABLE_PATH ..."
    return
  fi
  # if the same entry with different deploy_date exist, deploy date is updated
  if [[ $(grep "$l_PRIM_KEY" $DATA_TABLE_PATH | wc -l) -gt 0 ]];then
    # entry already exists, replace deployment date
    if [[ $VERBOSE == 'true' ]];then 
      log_msg write_data_table_entry " * Found $l_PRIM_KEY in $DATA_TABLE_PATH ..."
      log_msg write_data_table_entry " * Update deployment date to: $DEPLOY_DATE ..."
    fi
    grep -v "$l_PRIM_KEY" $DATA_TABLE_PATH > tmp_data_path
    (cat tmp_data_path;echo "${DEPLOY_DATE};${l_PRIM_KEY}") > $DATA_TABLE_PATH
    rm tmp_data_path
  else
    echo "${DEPLOY_DATE};${l_PRIM_KEY}" >> $DATA_TABLE_PATH
  fi
}



#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
QSL_NAME=''
SRC_QSL_ROOT=''
SRC_QSL_DIR=''
SRC_QSL_PATH=''
TRG_DPL_DIR=''
DEPLOY_DATE=''
LINK_TITLE=''
DATA_TABLE_PATH=''
QYMLPAR=''
COPYDIR=''
MOVEDIR=''
MOVEFILE=''
PREVIEW='false'
VERBOSE='false'
while getopts ":d:hl:q:s:t:vw:z" FLAG; do
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
    q)
      QYMLPAR=$OPTARG
      ;;
    s)
      QSL_NAME=$OPTARG
      ;;
    t)
      TRG_DPL_DIR=$OPTARG
      ;;
    v)
      PREVIEW='true'  
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
if [[ $SRC_QSL_ROOT == '' ]];then
  SRC_QSL_ROOT=$EVALREPO/inst/slides
fi
if [[ $QSL_NAME == '' ]];then
  usage " *** ERROR: -s <source_path|slides_name> required, but not defined ..."
fi
# generate qmd path from input or from slides name
if [[ -f $QSL_NAME ]];then
  SRC_QSL_PATH=$QSL_NAME
  QSL_NAME=$(basename $QSL_NAME | cut -d '.' -f1)
else
  SRC_QSL_PATH=$SRC_QSL_ROOT/$QSL_NAME/$QSL_NAME.qmd
fi
# directory of slides
if [[ $SRC_QSL_DIR == '' ]];then
  SRC_QSL_DIR=$(dirname $SRC_QSL_PATH)
fi
# check existence of path to qmd source file
if [[ ! -f $SRC_QSL_PATH ]];then
  usage " *** ERROR: CANNOT FIND path to qmd source file at: $SRC_QSL_PATH"
fi
if [[ $TRG_DPL_DIR == '' ]];then
  TRG_DPL_DIR=$EVALREPO/docs/slides/$QSL_NAME
fi
# check existence of deploy target directory
if [[ ! -d $TRG_DPL_DIR ]];then
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Create trg dir: $TRG_DPL_DIR ...";fi
  mkdir -p $TRG_DPL_DIR
fi
if [[ $DEPLOY_DATE == '' ]];then
  DEPLOY_DATE=$(date +"%Y-%m-%d")
fi
if [[ $LINK_TITLE == '' ]];then
  LINK_TITLE=$(grep 'title:' $SRC_QSL_PATH | cut -d ':' -f2 | sed -e "s/^ //" | sed -e "s/\"//g")
fi
if [[ $DATA_TABLE_PATH == '' ]];then
  DATA_TABLE_PATH=$EVALREPO/inst/website/lbgfs2024/slides/slides.dat
fi
if [[ $QYMLPAR == '' ]];then
  QYMLPAR=$SRC_QSL_DIR/_quarto.yml
fi
# deployment parameters
if [[ $COPYDIR == '' ]];then
  COPYDIR='png'
fi
if [[ $MOVEDIR == '' ]];then
  MOVEDIR="${QSL_NAME}_files"
fi
if [[ $MOVEFILE == '' ]];then
  MOVEFILE=${QSL_NAME}.html
fi

# log parameter values
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check args and defaults ..."
  log_msg $SCRIPT "   ==> SRC_QSL_ROOT:      $SRC_QSL_ROOT ..."
  log_msg $SCRIPT "   ==> SRC_QSL_DIR:       $SRC_QSL_DIR ..."
  log_msg $SCRIPT "   ==> SRC_QSL_PATH:      $SRC_QSL_PATH ..."
  log_msg $SCRIPT "   ==> QSL_NAME:          $QSL_NAME ..."
  log_msg $SCRIPT "   ==> TRG_DPL_DIR:       $TRG_DPL_DIR ..."
  log_msg $SCRIPT "   ==> DEPLOY_DATE:       $DEPLOY_DATE ..."
  log_msg $SCRIPT "   ==> LINK_TITLE:        $LINK_TITLE ..."
  log_msg $SCRIPT "   ==> DATA_TABLE_PATH:   $DATA_TABLE_PATH ..."
  log_msg $SCRIPT "   ==> QYMLPAR:           $QYMLPAR ..."
  log_msg $SCRIPT "   ==> PREVIEW:           $PREVIEW ..."
  log_msg $SCRIPT "   ==> COPYDIR:           $COPYDIR ..."
  log_msg $SCRIPT "   ==> MOVEDIR:           $MOVEDIR ..."
  log_msg $SCRIPT "   ==> MOVEFILE:          $MOVEFILE ..."
fi
  

#' ## Render and Preview
#' Render and preview the qmd source document
#+ render-and-preview
log_msg $SCRIPT " * Render or preview ..."
quarto_preview_render


#' ## Deployment
#' Copy and move material to deployment directory
#+ deploy-to-target
log_msg $SCRIPT " * Deploy material ..."
deploy_material


#' ## Write Entry to Data Table
#' Write an entry to the data table
#+ write-data-table-entry
log_msg $SCRIPT " * Write data table entry ..."
write_data_table_entry


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

