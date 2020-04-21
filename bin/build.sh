#!/bin/bash 

function usage {
    echo
    echo "VERSIONS is a space delimited list of branches and or tags."
    echo "e.g. 1.7 fixes/foo"
    echo
    echo " -b The images bases, e.g. apache-debian fpm-alpine"
    echo " -t The timezone, e.g. Europe/London"
    echo " -s The stages, e.g. dev prod"
    echo " -k Do not use Docker Build Kit"
    echo " -c Use the docker cache, default behaviour is to add --nocache"
    echo " -m Build for arm and amd64.  This will auto push so it should not be"
    echo "    used until the images have been built and tested for the native"
    echo "    playform."
    echo " -h Show help"
}

export DOCKER_BUILDKIT=1
export TZ=Europe/London
export STAGES="dev prod"
export BASES="apache-debian fpm-alpine"
NOCACHE="--no-cache"

USAGE="$0 [-t TIMEZONE] [-b BASES] [-s STAGES] [-k] [-c] [-h] VERSIONS"

while getopts "b:t:s:kchm" options; do
    case $options in
        b) export BASES="$OPTARG";;
        s) export STAGES="$OPTARG";;
        t) export TZ="$OPTARG";;
        k) unset DOCKER_BUILDKIT;;
        c) unset NOCACHE;;
        m) export MULTIARCH=1;;
        h) echo $USAGE; usage; exit 0;;
    esac
done

shift $((OPTIND-1))
export KIMAIS=$@

if [ ! -z "$1" ] && [ -z "$KIMAIS" ]; then
    KIMAIS=$@
fi

if [ "$MULTIARCH" == "1" ]; then
    if [ -e $HOME/.docker/cli-plugins/docker-buildx ]; then
        BUILDX=buildx
        PLATFORM="--platform linux/amd64,linux/arm64 --push"
        TAG=multiarch-
    else
        echo -e "\x1b[31;01mMultiarch build requested but buildx is not installed\x1b[39;49;00m, see https://tech.smartling.com/building-multi-architecture-docker-images-on-arm-64-c3e6f8d78e1c"
    fi
fi

for KIMAI in $KIMAIS; do
    for STAGE_NAME in $STAGES; do
        for BASE in $BASES; do
            docker $BUILDX build $PLATFORM $NOCACHE -t kimai/kimai2:$TAG${BASE}-${KIMAI}-${STAGE_NAME} --build-arg KIMAI=${KIMAI} --build-arg BASE=${BASE} --build-arg TZ=${TZ} --target=${STAGE_NAME} $(dirname $0)/..
        done
    done
done
