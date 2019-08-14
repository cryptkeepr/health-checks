#!/usr/bin/env bash

## =============================================================================
#   title       health-checks
#   description Runs health-checks on on designated system services
#   git url     https://github.com/cryptkeepr/health-checks.git
#   author      Eric Fledderman
#   version     1.1.0
#   usage       bash health-checks.sh
#   notes       All runtime data stores in 'vars' file
#
#   changelog
# ------------------------------------------------------------------------------
#   Date          Version    Notes
# ------------------------------------------------------------------------------
#   2019-08-14    v1.0.1     Reformatting of console output
#   2019-08-10    v1.0.0     Initial code
## =============================================================================




## *****************************************************************************
#   NOTICE!!!
## *****************************************************************************
#   It is highly recommended to schedule this script to run periodically via
#   a cronjob




## -----------------------------------------------------------------------------
#   Global Variables
## -----------------------------------------------------------------------------

APP_NAME=$(basename "$0" .sh)
APP_VERSION="1.0.0"

APP_DIR="$(cd "$(dirname "$0")" ; pwd -P)"
APP_VARS="$(echo "${APP_DIR}"/vars)"


## -----------------------------------------------------------------------------
#   Styling
## -----------------------------------------------------------------------------

# Colors
BLUE="\033[1;34m"
GRAY="\033[1;30m"
GRAYL="\033[0;37m"
GREEN="\033[0;32m"
RED="\033[0;31m"
ORANGE="\033[0;33m"
WHITE="\033[1;37m"
NC="\033[0m"

# Font styles
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
NS="\e[0m"


## -----------------------------------------------------------------------------
#   Functions
## -----------------------------------------------------------------------------

###
 #  Verifies that the 'vars' files exists and there is data within it
 ##
config_check () {
  # 'var's exists check
  if [[ ! -f "${APP_VARS}" ]]; then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} The 'var's file does not exist.\n"
    printf "$(timestamp) ${YELLOW}Exiting...${NC}\n"
    exit 1
  fi

  # 'var's empty check
  if [[ ! -s "${APP_VARS}" ]]; then
    printf "$(timestamp) ${GRAY}[${RED}ERROR${GRAY}]${NC} The 'var's file exists, but has no contents.\n"
    printf "$(timestamp) ${YELLOW}Exiting...${NC}\n"
    exit 1
  fi
}

###
 #  Evaluates the log file size. If it exceeds 1GB, function will tim line by
 #  line until the log file size is smaller tha 0.5GB (529,288 bytes)
 ##
log_check () {
  # Check if log file size exceeds 1GB
  if [ $(du -k ${APP_DIR}/.log | cut -f 1) -ge 1048576 ]; then
    printf "$(timestamp) ${GRAY}[${ORANGE}ALERT${GRAY}]${NC} Log file size has exceeded 1GB:\n" 2>&1 | tee -a ${APP_DIR}/.log
    printf "$(timestamp)   ${DIM}- Trimming:${NS} "

    # Continue trimming until log file size is smaller than 0.5GB
    while [ $(du - ${APP_DIR}/.log | cut -f 1) -ge 529288 ]; do
      # Trim line by line
      sec -i "1d" ${APP_DIR}/.log
    done
    printf "${GRAY}[${GREEN}DONE${GRAY}]${NC}\n"
  fi
}

###
 #  Creates a timestamp to be used in printed statements
 ##
timestamp () {
  date +"${GRAY}[${DIM}%Y-%m-%d %T${GRAY}]${NC}"
}


## -----------------------------------------------------------------------------
#   Application
## -----------------------------------------------------------------------------

# "Splash Screen"
printf "$(timestamp) ${BOLD}${UNDERLINE}${WHITE}Running Health Checks${NC}${NS}\n"

# Check that configuration was successful
config_check

# Check that the log file hasn't exceeded 1GB
log_check

# Loop through system services
while read f1 f2; do
  # Value is appended to the end of curl command
  TAIL=""

  # Display current service being processed
  printf "$(timestamp) ${WHITE}${f1}${NC}\n"

  # Perform status check on system service
  printf "$(timestamp)   ${DIM}- Status check:${NC}     "
  STATUS="$(systemctl is-active --quiet "${f1}".service && echo true)"

  if [ "${STATUS}" = "true" ]; then
    printf "${GREEN}PASS${NC}\n"
  else
    printf "${RED}FAIL${NC}\n"
  fi

  # Report results of system service status check
  printf "$(timestamp)   ${DIM}- Reporting status:${NC} "

  if [ ! "${STATUS}" = "true" ]; then
    TAIL="/fail"
  fi

  RESPONSE=$(curl --silent --retry 3 --output /dev/null --write-out '%{http_code}' "${f2}${TAIL}")

  if [ "${RESPONSE}" == 200 ]; then
    printf "${GREEN}PASS${NC}\n"
  else
    printf "${RED}FAIL${NC}\n"
  fi

  # Pause to prevent being flagged as spam
  sleep 1s
done < "${APP_VARS}"

# Print empty line to .log and then exit
echo
exit 0
