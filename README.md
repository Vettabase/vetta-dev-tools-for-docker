# Vetta Dev Tools for Docker

Tools to develop and build Docker images.

These tools were written to build and test Docker images that
can be found in [vettadock](https://hub.docker.com/u/vettadock).


## Install

Create a configuration file from the template:

```
cp config-build.sh.default config-build.sh
chmod u+wx config-build.sh
```

Adjust the settings in `config-build.sh`.


## Configuration

Each configuration option is an environment variable set and documented
in the `config-build.sh.default` file, and in the `build.sh` help, that
you can see with `HELP=1 ./build.sh`. This paragraph is meant to give you
the big picture.


### Basic Configuration

It's recommended to copy Vetta Dev Tools for Docker into a Docker image
project's subdirectory. Then set `DIR` to the parent directory.
In this way, each copy of Vetta Dev Tools for Docker will contain
configuration for a single Docker image.

If you use Vetta Dev Tools for Docker in the recommended way, set
`DEFAULT_IMAGE` to the image name.

If the Docker image project consists of a single tag, or if you
work on a single tag while the others are more or less frozen, you
may want to set `DEFAULT_TAG`, too.


### Usability and Accessibility

By default, `USE_COLOURS` is set to 0, so the output of the scripts
appear in the default colour (normally white or black). This is good
for some visually impaired people and also some people with good
eyesight. You can change this value to 1, if you wish so.


### Tests

After building images with `build.sh`, it is possible to start a container
and test it with `test-build.sh`. The performed tests depend on the
configuration.

`SHOULD_RUN=1` (default) means that `test-build.sh` will check
wether the container is running. Set to 0 to disable.

`SHOULD_ECHO=1` (default) means that `test-build.sh` will check
wether the container is able to run an `echo` command. Set to 0
to disable.

An optional test consists in running a custom command with
`docker exec`, pipe its output to `grep`, and check that a
given regex succeeds. `SHOULD_EXEC_QUESTION` is the command
to run, and `SHOULD_GREP_ANSWER` is the regexp to test.


## Copyright and License

Vettabase Ltd  2020, 2021<br/>
License: GNU GPL 3<br/>
See `LICENSE` file.


