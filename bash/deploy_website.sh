#!/bin/bash
#' ---
#' title: Deploy Website
#' date:  20240918
#' author: Peter von Rohr
#' ---
#' 
#' ## Modifications
#'   [Date]     | [Who]    | [What has been modified ...] 
#' -------------|----------|-----------------------------------
#' 
#' ## Purpose
#' Seamless deployment of new version of the website
#'
#' ## Description
#' Deploy a new version of the website
#'
#' ## Details
#' This includes re-rendering of all quarto markdown pages plus copying the generated html-pages to the target directory
#'
#' ## Example
#' ./deploy_website.sh
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
  echo "Usage:   $SCRIPT -h -p -z"
  echo '  where '
  echo '        -h  --  (optional) show usage message ...'
  echo '        -p  --  (optional) directly publish rendered content ...'
  echo '                           > default: false'
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
QWEBPROJROOT=''
PUBWEBDIR=''
PUBLISH_CONTENT='false'
VERBOSE='false'
while getopts ":hpz" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    p)
      PUBLISH_CONTENT='true'
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
if [[ $QWEBPROJROOT == '' ]];then
  QWEBPROJROOT=$EVALREPO/inst/website/lbgfs2024
fi
if [[ $PUBWEBDIR == '' ]];then
  PUBWEBDIR=$EVALREPO/docs
fi
if [[ $VERBOSE == 'true' ]];then
  log_msg $SCRIPT " * Check and set parameter values ..."
  log_msg $SCRIPT " * *** QWEBPROJROOT: $QWEBPROJROOT ..."
  log_msg $SCRIPT " * *** PUBWEBDIR:    $PUBWEBDIR ..."
fi


#' ## Render Quarto Markdown
#' Render qmd files
#+ render-qmd-files
log_msg $SCRIPT " * Render qmd ..."
cd $QWEBPROJROOT
QRENDOPT=''
if [[ $VERBOSE == 'true' ]];then
  QRENDOPT="${QRENDOPT} -z"
fi
./bash/quarto_render.sh "$QRENDOPT"
cd $EVALREPO


#' ## Deployment of Rendering Results
#' The results of the rendering are copied to the directory from where the 
#' website is served
#+ deploy-website
log_msg $SCRIPT " * Deploy website ..."
for f in $(find $QWEBPROJROOT/_site -type f -name '*.html');do
  TRGWEBPATH=$(echo $f | sed -e "s|$QWEBPROJROOT/_site|$PUBWEBDIR|")
  # target web directory must exist, otherwise create it
  TRGWEBDIR=$(dirname $TRGWEBPATH)
  check_exist_create_dir $TRGWEBDIR
  if [[ $VERBOSE == 'true' ]];then log_msg $SCRIPT " * Copy $f to $TRGWEBPATH ...";fi
  cp $f $TRGWEBPATH
done


#' ## Publish Content
#' Directly publish content by committing all changes and by 
#' pushing everything to Github
#+ publish-content
if [[ $PUBLISH_CONTENT == 'true' ]];then
  log_msg $SCRIPT " * Publish content ..."
  $EVALREPO/bash/stepwise_commit_push.sh -s modified
fi



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

