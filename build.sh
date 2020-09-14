#! /bin/bash


## This file is part of Vetta Dev Tools for Docker.
## Copyright: Vettabase Ltd  2020
## License: GNU GPL3. See LICENSE file.

# Build an image from a Dockerfile.


if [ ! -z "$HELP" ];
then
    echo '
build.sh
Build a Docker image handling options in a safe way

Syntax:
[ DRY=1 ] [ IMAGE=str ] [ TAG=str ] [ CACHE=1 ] ./build.sh

DRY=1
    Show the build command and exit without running it.
IMAGE
    Name of the image to build
TAG
    Image tag
DIR
    Path of the Dockerfile. By default, it is a directory called
    $TAG, located in the current directory
CACHE=1
    Force to use the cache. If not specified,
    or if any other value is passed, the cache will be used.

Default values for IMAGE and TAG can also be set in config-build.sh.
'
exit 0
fi


HERE="`dirname \"$0\"`"
HERE=`( cd "$HERE" && pwd )`
source $HERE/config-build.sh

# IMAGE and TAG are mandatory.
# If missing, set to default or return error.

if [ -z "$IMAGE" ];
then
    IMAGE=$DEFAULT_IMAGE
fi
if [ -z "$TAG" ];
then
    TAG=$DEFAULT_TAG
fi
if [ -z "$IMAGE" ] || [ -z "$TAG" ];
then
    echo 'ABORT: IMAGE and TAG variables are mandatory.'
    echo 'If you need help, run:'
    echo 'HELP=1 ./build.sh'
    exit 1
fi

# Default value for $DIR
if [ -z "$DIR" ];
then
    DIR=$( pwd )"/$TAG"
fi

# By default, --no-cache is used. To use the cache, specify CACHE=1
if [ $CACHE=='1' ];
then
    OPTIONS=''
else
    OPTIONS='--no-cache'
fi


# Build image
cmd="docker build $OPTIONS --tag $IMAGE:$TAG $DIR"
echo 'Build command:'
echo $cmd
echo

if [ ! -z "$DRY" ];
then
    echo 'Exiting gracefully because $DRY option was specified'
    echo
    exit 0
fi

$cmd


