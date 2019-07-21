#!/usr/bin/env bash

# Flag used to indicate whether the working folder has a Dockerfile and a README.md file
# that defines IMAGE and VERSION.
can_build=0

# The graphic is taken from GBox and the Doom font is used for 'Getaround' to be
# consistent with GBox. The Calvin S font is used for 'Microservices'.
# Fonts: http://patorjk.com/software/taag/
GREEN='\033[0;32m'
NO_COLOR='\033[0m'
echo -e "${GREEN}
╔╦╗ ┬ ┌─┐ ┬─┐ ┌─┐ ┌─┐ ┌─┐ ┬─┐ ┬  ┬ ┬ ┌─┐ ┌─┐ ┌─┐
║║║ │ │   ├┬┘ │ │ └─┐ ├┤  ├┬┘ └┐┌┘ │ │   ├┤  └─┐
╩ ╩ ┴ └─┘ ┴└─ └─┘ └─┘ └─┘ ┴└─  └┘  ┴ └─┘ └─┘ └─┘
${NO_COLOR}
   Type ${GREEN}commands${NO_COLOR} to see a list of commands.
"

###########################
# Print a list of commands.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###########################
commands() {
  echo -e "
  ${GREEN}commands${NO_COLOR}     Print a list of commands.
  ${GREEN}dev${NO_COLOR}          Build the image for the current Dockerfile and launch the container with a bash session.
  ${GREEN}run${NO_COLOR}          Build the image for the current Dockerfile and run the container locally.
"
}

################################################################################
# Build the image for the current Dockerfile and launch the container with bash.
# Globals:
#   can_build
# Arguments:
#   None
# Returns:
#   None
################################################################################
dev() {
  _ensure_build
  if [[ ${can_build} == 0 ]]; then
    return
  fi

  _ensure_network

  tag=$(_make_tag)

  docker build \
    -t ${tag} \
    .

  docker run \
    --entrypoint /bin/bash \
    --interactive \
    --mount source=$PWD,destination=/app,type=bind \
    --name $(_make_name) \
    --network main \
    $(_make_publish_options) \
    --rm \
    --tty \
    ${tag}
}

###########################################################################
# Build the image for the current Dockerfile and run the container locally.
# Globals:
#   can_build
# Arguments:
#   None
# Returns:
#   None
###########################################################################
run() {
  _ensure_build
  if [[ ${can_build} == 0 ]]; then
    return
  fi

  _ensure_network
  _remove_image

  tag=$(_make_tag)

  docker build \
    -t ${tag} \
    .

  docker run \
    -d \
    --mount source=$PWD,destination=/app,type=bind \
    --network main \
    --name $(_make_name) \
    $(_make_publish_options) \
    ${tag}
}

#############################################
# Ensure the current folder has a Dockerfile.
# Globals:
#   can_build
# Arguments:
#   None
# Returns:
#   None
#############################################
_ensure_build() {
  can_build=1
  if [[ ! -f Dockerfile ]]; then
    printf "Must be in a folder with a Dockerfile\n"
    can_build=0
    return
  fi
}

###################################
# Ensure the Docker network exists.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###################################
_ensure_network() {
  network=$(docker network ls | grep main)
  if [[ -z "$network" ]]; then
    docker network create --driver=bridge main
  fi
}

#################################################################
# Make a user-friendly container name for the current Dockerfile.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The name of the container as a string.
#################################################################
_make_name() {
  name=$(basename "`pwd`")
  printf "$name"
}

######################################################################################
# Make publish options for docker run from the unique exposed ports in the Dockerfile.
# We could use --publish-all and avoid possible port conflicts, but this allows more
# developer consistency.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   A string with publish options for docker run.
######################################################################################
_make_publish_options() {
  ports=($(cat Dockerfile | grep EXPOSE | sort -u | cut -d' ' -f2))
  publish=""
  for port in "${ports[@]}"
  do
     publish+="--publish $port:$port "
  done
  echo "$publish"
}

##########################################
# Make the tag for the current Dockerfile.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The tag as a string.
##########################################
_make_tag() {
  name=$(_make_name)
  printf "$name:latest"
}

#######################################################
# Stop and remove the image for the current Dockerfile.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The name of the image as a string.
#######################################################
_remove_image() {
  name=$(_make_name)

  docker kill ${name} &> /dev/null
  docker rm ${name} &> /dev/null
}
