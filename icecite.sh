#!/bin/sh
### BEGIN INIT INFO
# Provides:          icecite
# Required-Start:    $all
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Starts Icecite.
### END INIT INFO

HOME="/home/icecite"
USER="korzen"
GROUP="ad-staff"

LOG_FILE_HOME=/var/log/icecite
LOG_FILE="$LOG_FILE_HOME/icecite.log"

PID_FILES_HOME=/var/run/icecite

MAKE=/usr/bin/make
RM=/bin/rm
CAT=/bin/cat
ECHO=/bin/echo
NOHUP=/usr/bin/nohup
KILL=/bin/kill
CP=/bin/cp
MKDIR=/bin/mkdir
CHMOD=/bin/chmod
CHOWN=/bin/chown
SUDO=/usr/bin/sudo
SU=/bin/su

# There are mainly 3 components to start/stop/maintain:
#   (1) CompleteSearch - an instance of CompleteSearch, that is used to search 
#       DBLP.
#   (2) MetadataKnowledge - a metadata knowledge server based on DBLP, that is 
#       used to enrich metadata extracted from PDF to *full* and *reliable* 
#       metadata.
#   (3) PdfMachine - a server that is used to find 
#        - PDF files for given metadata. 
#        - Metadata for given PDF files. 

# ------------------------------------------------------------------------------
# (1) Methods to start and stop CompleteSearch.

CS_HOME="$HOME/completesearch/databases/dblp"
#CS_HOME="/home/korzen/completesearch/databases/dblp"
CS_PORT=6201
 
start_completesearch() {
  $SUDO $SU $USER -c "$MAKE -C $CS_HOME start PORT=$CS_PORT > $LOG_FILE 2>&1"
}

stop_completesearch() {
  $SUDO $SU $USER -c "$MAKE -C $CS_HOME stop PORT=$CS_PORT > $LOG_FILE 2>&1"
}

# ------------------------------------------------------------------------------
# (2) Methods to start and stop MetadataKnowledge.

MK_HOME="$HOME/metadata-knowledge"
#MK_HOME="/home/korzen/icecite.OLD/dblpmatching"
MK_PID="$PID_FILES_HOME/metadataknowledge.pid"
MK_PORT=6200

start_metadataknowledge() {
  # Define the command to execute.
  MK_CMD="$NOHUP $MAKE -C $MK_HOME start PORT=$MK_PORT > $LOG_FILE 2>&1"
  # Run the command with given user and keep track of the pid.
  $SUDO $SU $USER -c "$MK_CMD & echo \$! > $MK_PID"
}

stop_metadataknowledge() {  
  if [ -f "$MK_PID" ]; then 
    if $KILL -0 $($CAT "$MK_PID"); then
      $KILL -15 $($CAT "$MK_PID") > $LOG_FILE 2>&1 && $RM -f "$MK_PID"
    else
      $RM -f "$MK_PID"  
    fi
  fi
}

# ------------------------------------------------------------------------------
# (3) Methods to start and stop PdfMachine.

PM_HOME="$HOME/pdf-machine"
#PM_HOME="/home/korzen/icecite.OLD/pdf-machine"
PM_HOME_WAR="$PM_HOME/target/pdf-machine.war"

TOMCAT_WEBAPPS_HOME="/var/lib/tomcat6/webapps"
PM_TOMCAT_CONTEXT="$TOMCAT_WEBAPPS_HOME/pdf-machine"
PM_TOMCAT_WAR="$TOMCAT_WEBAPPS_HOME/pdf-machine.war"

start_pdfmachine() {
  # Check if context directory and war exist in webapps directory of tomcat.
  if [ ! -d "$PM_TOMCAT_CONTEXT" ] && [ ! -f "$PM_TOMCAT_WAR" ]; then
    # Copy the war file to webapps directory.
    $CP "$PM_HOME_WAR" "$TOMCAT_WEBAPPS_HOME" > $LOG_FILE 2>&1
  fi
}

stop_pdfmachine() {
  # Nothing to do
  return 0
}

# ------------------------------------------------------------------------------
# 

create_dirs() {
  # Create the log directory if it doesn't exist.
  if [ ! -d "$LOG_FILE_HOME" ]; then
    $MKDIR -p "$LOG_FILE_HOME"
    $CHOWN $USER:$GROUP "$LOG_FILE_HOME"
  fi
  
  # Create the pid directory if it doesn't exist.
  if [ ! -d "$PID_FILES_HOME" ]; then
    $MKDIR -p "$PID_FILES_HOME"
    $CHOWN $USER:$GROUP "$PID_FILES_HOME"
  fi
}

check_status() {
  local status=$?
  if [ $status -ne 0 ]; then
    printf "Failed! See $LOG_FILE for more details.\n" >&2
    exit $status
  else
    printf "Done!\n"
  fi
}

# ------------------------------------------------------------------------------
#

start() {
  printf "Create needed directories … " >&2
  create_dirs
  check_status
     
  # (1) Start CompleteSearch. 
  printf "Starting CompleteSearch … " >&2
  start_completesearch
  check_status
  
  # (2) Start MetadataKnowledge. 
  printf "Starting MetadataKnowledge … " >&2
  start_metadataknowledge
  check_status
  
  # (3) Start PdfMachine.
  printf "Starting PdfMachine … " >&2 
  start_pdfmachine
  check_status
}

stop() {
  printf "Create needed directories … " >&2
  create_dirs
  check_status
    
  # (1) Stop CompleteSearch
  printf "Stopping CompleteSearch … " >&2
  stop_completesearch
  check_status
  
  # (2) Stop MetadataKnowledge
  printf "Stopping MetadataKnowledge … " >&2
  stop_metadataknowledge
  check_status
  
  # (3) Stop PdfMachine. 
  printf "Stopping PdfMachine … " >&2
  stop_pdfmachine
  check_status
}

# ------------------------------------------------------------------------------
#

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

