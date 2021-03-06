#!/usr/bin/env bash
#
# GApps compilation script
#
# Copyright (C) 2016-2017 Nathan Chancellor
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>


###########
#         #
#  USAGE  #
#         #
###########

# PURPOSE: Build GApps zip (either Open or Beans GApps)
# USAGE: $ bash gapps.sh -h


###############
#             #
#  FUNCTIONS  #
#             #
###############

# SOURCE OUR UNIVERSAL FUNCTIONS SCRIPT
source $( dirname ${BASH_SOURCE} )/funcs.sh

# MAC CHECK; THIS SCRIPT SHOULD ONLY BE RUN ON LINUX
if [[ $( uname -a | grep -i "darwin" ) ]]; then
    reportError "Wrong window! ;)" -n && exit
fi

# PRINT A HELP MENU IF REQUESTED
function help_menu() {
    echo -e ""
    echo -e "${BOLD}OVERVIEW:${RST} Builds a GApps zip (either Open or Beans)\n"
    echo -e "${BOLD}USAGE:${RST} bash ${0} <gapps> <variant>\n"
    echo -e "${BOLD}EXAMPLE:${RST} bash ${0} open nano\n"
    echo -e "${BOLD}REQUIRED PARAMETERS:${RST}"
    echo -e "   gapps:      open | beans\n"
    echo -e "${BOLD}SECONDARY PARAMETERS:${RST}"
    echo -e "   variant:    (open only) super | stock | full | mini | micro | nano | pico\n"
    exit
}


################
#              #
#  PARAMETERS  #
#              #
################

# RESET SUCCESS FLAG
SUCCESS=false

while [[ $# -ge 1 ]]; do
    case "${1}" in
        "open"|"beans")
            TYPE=${1} ;;
        "super"|"stock"|"full"|"mini"|"micro"|"nano"|"pico")
            VERSION=${1} ;;
        "-h"|"--help")
            help_menu ;;
        *)
            reportError "Invalid parameter" && exit ;;
    esac

    shift
done

if [[ -z ${TYPE} ]] || [[ ${TYPE} = "open" && -z ${VERSION} ]]; then
    reportError "You did not specify a necessary parameter (either type of GApps or variant of GApps). Please re-run the script with the necessary parameters!" && exit
fi

###############
#             #
#  VARIABLES  #
#             #
###############

ANDROID_DIR=${HOME}
ZIP_MOVE=${HOME}/Web/Downloads/.superhidden/GApps

# Type logic
case ${TYPE} in
    "beans")
        SOURCE_DIR=${ANDROID_DIR}/GApps/Beans
        ZIP_FORMAT=*Beans*.zip
        BRANCH=n-mr2 ;;
    "open")
        SOURCE_DIR=${ANDROID_DIR}/GApps/Open
        ZIP_FORMAT=open*${VERSION}*.zip
        BRANCH=master ;;
esac


##################
#                #
#  SCRIPT START  #
#                #
##################

# SET THE START OF THE SCRIPT
START=$( TZ=MST date +%s )


# MOVE INTO SOURCE FOLDER
clear && cd ${SOURCE_DIR}


############
# CLEAN UP #
############

if [[ ${TYPE} = "beans" ]]; then
    echoText "CLEANING UP REPO"

    git reset --hard origin/${BRANCH}
    git clean -f -d -x
fi


#####################
# FETCH NEW CHANGES #
#####################

echoText "UPDATING REPO"

git pull
if [[ ${TYPE} = "open" ]]; then
    ./download_sources.sh --shallow arm64
fi


##############
# MAKE GAPPS #
##############

echoText "BUILDING $( echo ${TYPE} | awk '{print toupper($0)}' ) GAPPS"

case "${TYPE}" in
    "beans")
        source mkgapps.sh both ;;
    "open")
        make arm64-25-${VERSION} ;;
esac


#####################
# IF GAPPS COMPILED #
#####################

# THERE WILL BE A ZIP IN THE OUT FOLDER IN THE ZIP FORMAT
if [[ $( ls ${SOURCE_DIR}/out/${ZIP_FORMAT} 2>/dev/null | wc -l ) != "0" ]]; then
    # MAKE BUILD RESULT STRING REFLECT SUCCESSFUL COMPILATION
    BUILD_RESULT_STRING="BUILD SUCCESSFUL"
    SUCCESS=true


    ##################
    # ZIP_MOVE LOGIC #
    ##################

    # MAKE ZIP_MOVE IF IT DOESN'T EXIST OR CLEAN IT IF IT DOES
    if [[ ! -d ${ZIP_MOVE} ]]; then
        mkdir -p ${ZIP_MOVE}
    else
        rm -rf ${ZIP_MOVE}/${ZIP_FORMAT}
    fi


    ######################
    # MOVING GAPPS FILES #
    ######################

    mv ${SOURCE_DIR}/out/${ZIP_FORMAT} ${ZIP_MOVE}


###################
# IF BUILD FAILED #
###################

else
    BUILD_RESULT_STRING="BUILD FAILED"
    SUCCESS=false
fi


##############
# SCRIPT END #
##############

END=$( TZ=MST date +%s )
newLine; echoText "${BUILD_RESULT_STRING}!"


######################
# ENDING INFORMATION #
######################

# IF THE BUILD WAS SUCCESSFUL, PRINT FILE LOCATION AND SIZE
if [[ ${SUCCESS} = true ]]; then
    echo -e ${RED}"FILE LOCATION: $( ls ${ZIP_MOVE}/${ZIP_FORMAT} )"
    echo -e "SIZE: $( du -h ${ZIP_MOVE}/${ZIP_FORMAT} | awk '{print $1}' )"${RST}
fi

# PRINT THE TIME THE SCRIPT FINISHED
# AND HOW LONG IT TOOK REGARDLESS OF SUCCESS
echo -e ${RED}"TIME FINISHED: $( TZ=MST date +%D\ %r | awk '{print toupper($0)}' )"
echo -e ${RED}"DURATION: $( format_time ${END} ${START} )"${RST}; newLine


##################
# LOG GENERATION #
##################

# DATE: BASH_SOURCE (PARAMETERS)
echo -e "\n$( TZ=MST date +"%m/%d/%Y %H:%M:%S" ): ${BASH_SOURCE} ${TYPE}" >> ${LOG}

# BUILD <SUCCESSFUL|FAILED> IN # MINUTES AND # SECONDS
echo -e "${BUILD_RESULT_STRING} IN $( format_time ${END} ${START} )" >> ${LOG}

# ONLY ADD A LINE ABOUT FILE LOCATION IF SCRIPT COMPLETED SUCCESSFULLY
if [[ ${SUCCESS} = true ]]; then
    # FILE LOCATION: <PATH>
    echo -e "FILE LOCATION: $( ls ${ZIP_MOVE}/${ZIP_FORMAT} )" >> ${LOG}
fi


########################
# ALERT FOR SCRIPT END #
########################

echo -e "\a" && cd ${HOME}
