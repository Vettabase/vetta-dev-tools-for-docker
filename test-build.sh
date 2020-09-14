#! /bin/bash


## This file is part of Vetta Dev Tools for Docker.
## Copyright: Vettabase Ltd  2020
## License: GNU GPL3. See LICENSE file.

# Test wether a Dockerfile builds
# and a container can be created.


# Abort execution.
# Depending on PRESERVE_CONTAINER,
# may remove the test container.
# Params:
# @EXIT_CODE        Script exit code
# @MESSAGE          Error message
function abort {
    EXIT_CODE=$1
    MESSAGE=$2
    echo -e "$ABORT: $MESSAGE"
    if [ "$PRESERVE_CONTAINER" == ON_ERROR ];
    then
        echo "Removing container $CONTAINER if it exists"
        docker rm -f $CONTAINER &> /dev/null
    fi
    exit $EXIT_CODE
}

# Print message to inform that a test failes.
# Terminate execution and, depending on
# PRESERVE_CONTAINER, may remove
# the test container.
# Params:
# @EXIT_CODE        If abort is required, use this exit code
# @MESSAGE          Error message
function fail {
    EXIT_CODE=$1
    MESSAGE=$2
    echo -e "$FAIL: $MESSAGE"
    if [ "$PRESERVE_CONTAINER" == 0 ];
    then
        echo "Removing container $CONTAINER if it exists"
        docker rm -f $CONTAINER &> /dev/null
    fi
    exit $EXIT_CODE
}


if [ ! -z "$HELP" ];
then
    echo '
test-build.sh
Test wether a Dockerfile builds and if a container can be
created from the resulting image

Syntax:
[ IMAGE=str ] [ TAG=str ] [ CONTAINER=str ] [ CACHE=1 ] ./test-build.sh

IMAGE
    Name of the image to build
TAG
    Tag to use for this test.
CONTAINER
    Name of the test container. If a container with this name
    exists, it will be removed first.
DIR
    Path of the Dockerfile. By default, it is a directory called
    $TAG, located in the current directory
PRESERVE_CONTAINER
    0: The container is destroyed after tests
    1: The container is preserved
    ON_ERROR: The container is only preserved if a test fails,
    to allow debugging.
CACHE=1
    Force to use the cache. If not specified,
    or if any other value is passed, the cache will be used.

A default value for IMAGE can also be set in config-build.sh.
Tag can also be omitted if TEST_DEFAULT_TAG is specified
in config-build.sh.
Default value for CONTAINER is specified in config-build-sh
as TEST_CONTAINER. If it is empty, "test" will be used.

Return codes:
    0 = Success, all tests pass
    1 = Error while setting up the container
    2 = SHOULD_RUN test has failed
    3 = SHOULD_ECHO test has failed
    4 = SHOULD_EXEC_QUESTION test has failed
'
exit 0
fi


HERE="`dirname \"$0\"`"
HERE=`( cd "$HERE" && pwd )`
source $HERE/config-build.sh

if [ "$USE_COLOURS" == '1' ];
then
    ABORT='\e[31mFAIL\e[39m'
    FAIL='\e[31mFAIL\e[39m'
    PASS='\e[32mPASS\e[39m'
    OK='\e[32mOK\e[39m'
else
    ABORT='ABORT'
    FAIL='FAIL'
    PASS='PASS'
    OK='OK'
fi

# IMAGE and TAG are mandatory.
# If missing, set to default or return error.

if [ -z "$IMAGE" ];
then
    IMAGE=$DEFAULT_IMAGE
fi
if [ -z "$TAG" ];
then
    TAG=$TEST_DEFAULT_TAG
fi
if [ -z "$IMAGE" ] || [ -z "$TAG" ];
then
    abort 1 $'IMAGE and TAG variables are mandatory.\nIf you need help, run: \nHELP=1 ./test-build.sh'
fi

# CONTAINER's default is TEST_CONTAINER.
# The fallback default is 'test'.
if [ -z "$CONTAINER" ];
then
    CONTAINER="$DEFAULT_CONTAINER"
fi
if [ -z "$CONTAINER" ];
then
    CONTAINER='test'
fi

# Default value for $DIR
if [ -z "$DIR" ];
then
    DIR=$( pwd )"/$TAG"
fi

# Default value for $PRESERVE_CONTAINER
if [ -z "$PRESERVE_CONTAINER" ];
then
    PRESERVE_CONTAINER="$PRESERVE_TEST_CONTAINER"
fi

# By default, --no-cache is used. To use the cache, specify CACHE=1
if [ $CACHE=='1' ];
then
    OPTIONS=''
else
    OPTIONS='--no-cache'
fi


# Build image
echo "build.sh is called with these ENV variables:
IMAGE=$IMAGE
TAG=$TAG
DIR=$DIR"
echo
$HERE/build.sh
r=$?
if [ $r -ne '0' ];
then
    exit $r
fi

docker rm -f $CONTAINER &> /dev/null
docker run --detach --name $CONTAINER $IMAGE:$TAG
r=$?
if [ $r -ne 0 ];
then
    abort 1 'docker run command has failed'
    exit $r
fi

docker start $CONTAINER &> /dev/null
r=$?
if [ $r -ne 0 ];
then
    abort 'docker start command has failed'
    exit $r
fi


# do tests

TESTS=0

if [ $SHOULD_RUN == '1' ];
then
    r=$( docker ps --filter "name=$CONTAINER" | grep $CONTAINER )
    if [ -z "$r" ];
    then
        fail 2 "Container '$CONTAINER' is not running"
    else
        echo -e "$PASS: container '$CONTAINER' is running"
        TESTS=1
    fi
fi

if [ $SHOULD_ECHO == '1' ];
then
    r=$( docker exec -ti $CONTAINER echo PingPong | grep --colour=never PingPong )
    if [ -z "$r" ];
    then
        fail 3 "Container '$CONTAINER' did not echo"
    else
        echo -e "$PASS: container '$CONTAINER' echoed as expected"
        TESTS=1
    fi
fi

if [ ! -z "$SHOULD_EXEC_QUESTION" ];
then
    cmd="docker exec -ti $CONTAINER $SHOULD_EXEC_QUESTION"
    r=$( eval "$cmd" | grep --colour=never $SHOULD_GREP_ANSWER )
    if [ -z "$r" ];
    then
        fail 4 "Container '$CONTAINER' did not exec $cmd, or did not return expected output"
    else
        echo -e "$PASS: container '$CONTAINER' run $cmd and returned expected output"
        TESTS=1
    fi
fi

if [ "$TESTS" == '1' ];
then
    echo -e "$OK: All tests passed"
else
    echo -e "$OK: Container was successfully created"
fi

if [ "$PRESERVE_CONTAINER" != 1 ];
then
    docker rm -f $CONTAINER &> /dev/null
fi

exit 0


