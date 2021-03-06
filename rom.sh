#!/usr/bin/env bash
#
# ROM compilation script
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

# PURPOSE: Build an Android ROM from source
# USAGE: $ bash rom.sh -h


###############
#             #
#  FUNCTIONS  #
#             #
###############

# SOURCE OUR UNIVERSAL FUNCTIONS SCRIPT
source $( dirname ${BASH_SOURCE} )/funcs.sh

# MAC CHECK; THIS SCRIPT SHOULD ONLY BE RUN ON LINUX
if [[ $( uname -a | grep -i "darwin" ) ]]; then
    reportError "Wrong window! ;)" && exit
fi

# PRINT A HELP MENU IF REQUESTED
function help_menu() {
    echo -e ""
    echo -e "${BOLD}OVERVIEW:${RST} Build a ROM\n"
    echo -e "${BOLD}USAGE:${RST} bash ${0} <rom> <device> <options>\n"
    echo -e "${BOLD}Example:${RST} bash ${0} flash angler user sync\n"
    echo -e "${BOLD}REQUIRED PARAMETERS:${RST}"
    echo -e "   rom:        abc | du | du-caf | krexus | lineageos | lineageoms | omni | pn | vanilla"
    echo -e "   device:     angler | bullhead | flo | hammerhead | marlin| sailfish | shamu\n"
    echo -e "${BOLD}STANDARD PARAMETERS:${RST}"
    echo -e "   sync:       performs a repo sync before building"
    echo -e "   clean:      performs the specified clean (e.g. clean installclean will run make installclean)"
    echo -e "   make:       performs the specified make (e.g. make SystemUI will run make SystemUI)"
    echo -e "   variant:    build with the specified variant (e.g. variant userdebug). Possible options: eng, userdebug, and user. Userdebug is the default.\n"
    echo -e "${BOLD}SPECIAL PARAMETERS:${RST}"
    echo -e "   type:       (Krexus only) sets the specified type as the build tag"
    echo -e "   pixel:      (Vanilla only) Builds a Pixel variant build"
    echo -e "   public:     (Vanilla only) Builds with the public tag\n"
    echo -e "No options will fallback to DU Angler userdebug\n"
    exit
}

# CHECKS IF MKA EXISTS
function make_command() {
    if [[ $( command -v mka ) ]]; then
        mka $@
    else
        make -j$( nproc --all ) $@
    fi
}


################
#              #
#  PARAMETERS  #
#              #
################

while [[ $# -ge 1 ]]; do
    PARAMS+="${1} "

    case "${1}" in
        # REQUIRED OPTIONS
        "angler"|"bullhead"|"flo"|"hammerhead"|"marlin"|"oneplus3"|"sailfish"|"shamu")
            DEVICE=${1} ;;
        "abc"|"du"|"du-caf"|"krexus"|"lineageos"|"lineageoms"|"omni"|"pn"|"vanilla")
            ROM=${1} ;;
        # STANDARD OPTIONS
        "sync")
            SYNC=true ;;
        "clean")
            shift
            if [[ $# -ge 1 ]]; then
                PARAMS+="${1} "
                export CLEAN_TYPE=${1}
            else
                reportError "Please specify a clean type!" && exit
            fi ;;
        "make")
            shift
            if [[ $# -ge 1 ]]; then
                PARAMS+="${1} "
                export MAKE_TYPE=${1}
            else
                reportError "Please specify a make item!" && exit
            fi ;;
        "variant")
            shift
            if [[ $# -ge 1 ]]; then
                PARAMS+="${1} "
                export VARIANT=${1}
            else
                reportError "Please specify a build variant!" && exit
            fi ;;
        # SPECIAL OPTIONS
        # KREXUS
        "type")
            shift
            if [[ $# -ge 1 ]]; then
                PARAMS+="${1} "
                export BUILD_TAG=${1}
            else
                reportError "Please specify a build type!" && exit
            fi ;;
        # VANILLA
        "pixel")
            export PIXEL=true ;;
        "public")
            export PUBLIC=true ;;

        "-h"|"--help")
            help_menu ;;
        *)
            reportError "Invalid parameter detected!" && exit ;;
    esac

    shift
done

# PARAMETER VERIFICATION
if [[ -z ${DEVICE} ]]; then
    DEVICE=angler
fi

if [[ -z ${ROM} ]]; then
    ROM=du
fi

if [[ -z ${VARIANT} ]]; then
    case ${ROM} in
        "krexus"|"pn")
            VARIANT=user ;;
        *)
            VARIANT=userdebug ;;
    esac
fi

###############
#             #
#  VARIABLES  #
#             #
###############

# ANDROID_DIR: Directory that holds all of the Android files
# OUT_DIR: Directory that holds the compiled ROM files
# SOURCE_DIR: Directory that holds the ROM source
# ZIP_MOVE: Directory to hold completed ROM zips
ANDROID_DIR=${HOME}
ZIP_MOVE_PARENT=${HOME}/Web/Downloads/.superhidden/ROMs

# Otherwise, define them for our various ROMs
case "${ROM}" in
    "abc")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/ABC
        ZIP_MOVE=${ZIP_MOVE_PARENT}/ABC/${DEVICE} ;;
    "du")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/DU
        ZIP_MOVE=${ZIP_MOVE_PARENT}/DirtyUnicorns/${DEVICE} ;;
    "du-caf")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/DU-CAF
        ZIP_MOVE=${ZIP_MOVE_PARENT}/DirtyUnicorns/${DEVICE} ;;
    "krexus")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/Krexus
        ZIP_MOVE=${ZIP_MOVE_PARENT}/Krexus/${DEVICE} ;;
    "lineageos")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/LineageOS
        ZIP_MOVE=${ZIP_MOVE_PARENT}/LineageOS/${DEVICE} ;;
    "lineageoms")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/LineageOMS
        ZIP_MOVE=${ZIP_MOVE_PARENT}/LineageOMS/${DEVICE} ;;
    "omni")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/Omni
        ZIP_MOVE=${ZIP_MOVE_PARENT}/Omni/${DEVICE} ;;
    "pn")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/PN
        ZIP_MOVE=${ZIP_MOVE_PARENT}/PureNexus/${DEVICE} ;;
    "vanilla")
        SOURCE_DIR=${ANDROID_DIR}/ROMs/Vanilla
        ZIP_MOVE=${ZIP_MOVE_PARENT}/Vanilla/${DEVICE} ;;
esac

OUT_DIR=${SOURCE_DIR}/out/target/product/${DEVICE}

# LOG NAME
LOG_NAME=${LOGDIR}/Compilation/ROMs/${ROM}-${DEVICE}-$(TZ=MST date +"%Y%m%d-%H%M").log

###########################
# MOVE INTO SOURCE FOLDER #
# AND START TRACKING TIME #
###########################

START=$( TZ=MST date +%s )
clear && cd ${SOURCE_DIR}


#############
# REPO SYNC #
#############

REPO_SYNC="repo sync"
FLAGS="-j$( nproc --all ) --force-sync -c --no-clone-bundle --no-tags --optimized-fetch --prune"

# IF THE SYNC IS REQUESTED, DO SO
if [[ ${SYNC} = true ]]; then
    echoText "SYNCING LATEST SOURCES"; newLine

    ${REPO_SYNC} ${FLAGS}
fi


###########################
# SETUP BUILD ENVIRONMENT #
###########################

echoText "SETTING UP BUILD ENVIRONMENT"

# CHECK AND SEE IF WE ARE ON ARCH
# IF SO, ACTIVARE A VIRTUAL ENVIRONMENT FOR PROPER PYTHON SUPPORT
if [[ -f /etc/arch-release ]]; then
    virtualenv2 ${HOME}/venv && source ${HOME}/venv/bin/activate
fi

source build/envsetup.sh


##################
# PREPARE DEVICE #
##################

echoText "PREPARING $( echo ${DEVICE} | awk '{print toupper($0)}' )"

# NOT ALL ROMS USE BREAKFAST
case "${ROM}" in
    "aosip")
        lunch aosip_${DEVICE}-${VARIANT} ;;
    "krexus")
        lunch krexus_${DEVICE}-${VARIANT} ;;
    "vanilla")
        if [[ ${DEVICE} == "angler" ]]; then
            export KBUILD_BUILD_USER=skye
            export KBUILD_BUILD_HOST=vanilla
        fi
        lunch vanilla_${DEVICE}-${VARIANT} ;;
    *)
        breakfast ${DEVICE} ${VARIANT} ;;
esac


############
# CLEAN UP #
############

echoText "CLEANING UP OUT DIRECTORY"

if [[ -n ${CLEAN_TYPE} ]] && [[ ${CLEAN_TYPE} != "noclean" ]]; then
    make_command ${CLEAN_TYPE}
elif [[ -z ${CLEAN_TYPE} ]]; then
    make_command clobber
fi


##################
# START BUILDING #
##################

echoText "MAKING FILES"; newLine

NOW=$( TZ=MST date +"%Y-%m-%d-%S" )

# MAKE THE REQUESTED ITEM
if [[ -n ${MAKE_TYPE} ]]; then
    make_command ${MAKE_TYPE} | tee -a ${LOG_NAME}

    ################
    # PRINT RESULT #
    ################

    newLine; echoText "BUILD COMPLETED!"
else
    # NOT ALL ROMS USE BACON
    case "${ROM}" in
        "aosip")
            make_command kronic | tee -a ${LOG_NAME} ;;
        "krexus")
            make_command otapackage | tee -a ${LOG_NAME} ;;
        "vanilla")
            make_command vanilla | tee -a ${LOG_NAME} ;;
        *)
            make_command bacon | tee -a ${LOG_NAME} ;;
    esac

    ###################
    # IF ROM COMPILED #
    ###################

    # THERE WILL BE A ZIP IN THE OUT FOLDER IF SUCCESSFUL
    FILES=$( ls ${OUT_DIR}/*.zip 2>/dev/null | wc -l )
    if [[ ${FILES} != 0 ]]; then
        # MAKE BUILD RESULT STRING REFLECT SUCCESSFUL COMPILATION
        BUILD_RESULT_STRING="BUILD SUCCESSFUL"
        SUCCESS=true


        ##################
        # ZIP_MOVE LOGIC #
        ##################

        # MAKE ZIP_MOVE IF IT DOESN'T EXIST OR CLEAN IT IF IT DOES
        if [[ ! -d "${ZIP_MOVE}" ]]; then
            mkdir -p "${ZIP_MOVE}"
        else
            rm -rf "${ZIP_MOVE}"/*
        fi


        ####################
        # MOVING ROM FILES #
        ####################

        if [[ ${FILES} = 1 ]]; then
            mv "${OUT_DIR}"/*.zip* "${ZIP_MOVE}"
        else
            for FILE in $( ls ${OUT_DIR}/*.zip* | grep -v ota ); do
                mv "${FILE}" "${ZIP_MOVE}"
            done
        fi


    ###################
    # IF BUILD FAILED #
    ###################

    else
        BUILD_RESULT_STRING="BUILD FAILED"
        SUCCESS=false
    fi

    ################
    # PRINT RESULT #
    ################

    echoText "${BUILD_RESULT_STRING}!"
fi


# DEACTIVATE VIRTUALENV IF WE ARE ON ARCH
if [[ -f /etc/arch-release ]]; then
    deactivate && rm -rf ${HOME}/venv
fi


######################
# ENDING INFORMATION #
######################

# STOP TRACKING TIME
END=$( TZ=MST date +%s )

# IF THE BUILD WAS SUCCESSFUL, PRINT FILE LOCATION, AND SIZE
if [[ ${SUCCESS} = true ]]; then
    echo -e ${RED}"FILE LOCATION: $( ls ${ZIP_MOVE}/*.zip )"
    echo -e "SIZE: $( du -h ${ZIP_MOVE}/*.zip | awk '{print $1}' )"${RST}
fi

# PRINT THE TIME THE SCRIPT FINISHED
# AND HOW LONG IT TOOK REGARDLESS OF SUCCESS
echo -e ${RED}"TIME: $( TZ=MST date +%D\ %r | awk '{print toupper($0)}' )"
echo -e ${RED}"DURATION: $( format_time ${END} ${START} )"${RST}
echo -e "\a"


##################
# LOG GENERATION #
##################

# DATE: BASH_SOURCE (PARAMETERS)
echo -e "\n$( TZ=MST date +"%m/%d/%Y %H:%M:%S" ): ${BASH_SOURCE} ${PARAMS}" >> ${LOG}

# BUILD <SUCCESSFUL|FAILED> IN # MINUTES AND # SECONDS
if [[ -n ${BUILD_RESULT_STRING} ]]; then
    echo -e "${BUILD_RESULT_STRING} IN \c" >> ${LOG}
fi
echo -e "$( format_time ${END} ${START} )" >> ${LOG}

# ONLY ADD A LINE ABOUT FILE LOCATION IF SCRIPT COMPLETED SUCCESSFULLY
if [[ ${SUCCESS} = true ]]; then
    # FILE LOCATION: <PATH>
    echo -e "FILE LOCATION: $( ls ${ZIP_MOVE}/*.zip )" >> ${LOG}
fi
