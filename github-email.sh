#!/bin/bash
# -----------------------------------------------------------------------------
# Retrieve a GitHub user's email address
#
# Based on: https://gist.github.com/sindresorhus/4512621
# -----------------------------------------------------------------------------

# Used to display usage
SCRIPT_NAME=$(basename $0)

# ANSI colour escape sequences
COLOUR_BLUE='\033[1;34m'
COLOUR_PINK='\033[1;35m'
COLOUR_DKGRAY='\033[30m'
COLOUR_DKRED='\033[31m'
COLOUR_YELLOW='\033[1;33m'
COLOUR_OFF='\033[0m'

# Colour definitions used by script
COLOUR_HEADER=$COLOUR_BLUE
COLOUR_WARNING=$COLOUR_YELLOW

# Base API URLs
API_GITHUB="https://api.github.com"
API_NPM="https://registry.npmjs.org"

# GitHub API token filename
FILE_GITHUB_TOKEN=$HOME/.ghtoken

# -----------------------------------------------------------------------------
# Global argument values parsed from the command line
# -----------------------------------------------------------------------------

# Toggles -q
ARG_QUIET=true

# Forces user's repository
unset ARG_REPOSITORY

# API token value from -t or $FILE_GITHUB_TOKEN
unset ARG_GITHUB_TOKEN

# GitHub username to look up
unset ARG_USERNAME

# Set to anything to show help and exit
unset ARG_HELP

# -----------------------------------------------------------------------------
# Script starts here
# -----------------------------------------------------------------------------
main() {
	check_requirements

  parse_commandline $@

  if [ ! -z "$ARG_HELP" ]; then
    show_usage
  fi

  # Save the GitHub token to a file, if one was parsed on the command line
  if [ ! -z "$ARG_GITHUB_TOKEN" ]; then
    echo $ARG_GITHUB_TOKEN > $FILE_GITHUB_TOKEN
  elif [ ! -z "$GITHUB_TOKEN" ]; then
    # Read the standard GITHUB_TOKEN environment variable
    ARG_GITHUB_TOKEN=$GITHUB_TOKEN
  fi

  # Read the GitHub token from a file (if it is greater than zero bytes)
  if [ -s "$FILE_GITHUB_TOKEN" ]; then
    ARG_GITHUB_TOKEN=$(cat $FILE_GITHUB_TOKEN)
  fi

  # Stop if no user name is given
  if [ -z "$ARG_USERNAME" ]; then
    show_usage
  fi

  # Suppress printing curl's output
  if [ "$ARG_QUIET" = true ]; then
    ARG_QUIET=-s
  fi

  # Command to run for fetching documents via HTTP REST API calls
  CMD="curl $ARG_QUIET"

  # Force token usage
  if [ -z "$ARG_GITHUB_TOKEN" ]; then
    warning "When run for the first time, provide a GitHub API token using:\n"
    warning "    $SCRIPT_NAME -u username -t [TOKEN]\n"
    warning "See README.md for instructions on generating a token."
    exit 1
  fi

  PARAM_GITHUB_TOKEN="access_token=$ARG_GITHUB_TOKEN"

  NAME_FORMAT='.name + " <" + .email + ">"'

  heading 'GitHub'
  $CMD "$API_GITHUB/users/$ARG_USERNAME?$PARAM_GITHUB_TOKEN" \
    | jq -r "select( .email != null ) | $NAME_FORMAT"

  heading 'npm'
  $CMD "$API_NPM/-/user/org.couchdb.user:$ARG_USERNAME" | jq -r "select( .email != null ) | $NAME_FORMAT"

  heading 'Recent Commits'
  $CMD "$API_GITHUB/users/$ARG_USERNAME/events?$PARAM_GITHUB_TOKEN" \
    | jq -r ".[] | .payload | select( .commits != null ) | .commits[].author | $NAME_FORMAT" 2>/dev/null \
    | sort \
    | uniq

  heading 'Recent Repository Activity'
  if [ -z "$ARG_REPOSITORY" ]; then
    # Get first repository if no repository is specified
    ARG_REPOSITORY="$($CMD "$API_GITHUB/users/$ARG_USERNAME/repos?type=owner&sort=updated&$PARAM_GITHUB_TOKEN" \
      | sed -nE 's#^.*"name": "([^"]+)",.*$#\1#p' \
      | head -n1)"
  fi

  # Find all commits against the repository
  $CMD "$API_GITHUB/repos/$ARG_USERNAME/$ARG_REPOSITORY/commits?$PARAM_GITHUB_TOKEN" \
    | jq -r ".[] | .commit | .author | $NAME_FORMAT" 2>/dev/null \
    | sort \
    | uniq
}

# -----------------------------------------------------------------------------
# Checks for required utilities and exits if not found
# -----------------------------------------------------------------------------
check_requirements() {
  required curl "https://curl.haxx.se/"
  required jq "https://stedolan.github.io/jq/"
}

# -----------------------------------------------------------------------------
# Checks for a required utility and exits if not found
#
# $1 - Command to execute
# $2 - Where to find the command
# -----------------------------------------------------------------------------
required() {
  if ! command -v $1 > /dev/null 2>&1; then
    warning "Install $1 from $2 before proceeding."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Sets the global command line argument values
# -----------------------------------------------------------------------------
parse_commandline() {
  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -d|--debug)
      ARG_DEBUG="$2"
      # Skip argument and value
      shift && shift
      ;;
      -h|-\?|--help)
      ARG_HELP="true"
      shift
      ;;
      -q|--quiet)
      ARG_QUIET="$2"
      shift && shift
      ;;
      -r|--repository)
      ARG_REPOSITORY="$2"
      shift && shift
      ;;
      -t|--token)
      ARG_GITHUB_TOKEN="$2"
      shift && shift
      ;;
      -u|--username)
      ARG_USERNAME="$2"
      shift && shift
      ;;
      *)
      ARG_USERNAME="$1"
      # Skip arguments
      shift
      ;;
    esac
  done
  set -- "${POSITIONAL[@]}"
}

# -----------------------------------------------------------------------------
# Shows accepted command line parameters
# -----------------------------------------------------------------------------
show_usage() {
  printf "Usage: $SCRIPT_NAME -u username " >&2
  printf "[-r repository] [-t token] [-q false]\n" >&2
  exit 1
}

# -----------------------------------------------------------------------------
# Prints coloured text to standard output
# -----------------------------------------------------------------------------
coloured_text() {
  printf "%b$1%b\n" "$2" "$COLOUR_OFF"
}

# -----------------------------------------------------------------------------
# Prints a warning message to standard output
# -----------------------------------------------------------------------------
warning() {
  coloured_text "$1" "$COLOUR_WARNING"
}

# -----------------------------------------------------------------------------
# Prints emphasized heading text to standard output
# -----------------------------------------------------------------------------
heading() {
  coloured_text "\n$1" "$COLOUR_HEADER"
}

main $@

