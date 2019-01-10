#!/usr/bin/env bash
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
ARG_REPOSITORY=

# API token value from -t or $FILE_GITHUB_TOKEN
ARG_GITHUB_TOKEN=

# GitHub username to look up
ARG_USERNAME=

# Set to anything to show help and exit
ARG_HELP=

# -----------------------------------------------------------------------------
# Script starts here
# -----------------------------------------------------------------------------
main() {
  parse_commandline $@

  if [ ! -z $ARG_HELP ]; then
    show_usage
  fi

  # Save the GitHub token to a file
  if [ ! -z $ARG_GITHUB_TOKEN ]; then
    echo $ARG_GITHUB_TOKEN > $FILE_GITHUB_TOKEN
  fi

  # Read the GitHub token from a file (if greater than zero bytes)
  if [ -s $FILE_GITHUB_TOKEN ]; then
    ARG_GITHUB_TOKEN=$(cat $FILE_GITHUB_TOKEN)
  fi

  # Stop if no user name is given
  if [ -z $ARG_USERNAME ]; then
    show_usage
  fi

  # Suppress printing curl's output
  if [ "$ARG_QUIET" = true ]; then
    ARG_QUIET=-s
	fi

  CMD="curl $ARG_QUIET"

  # Force token usage
  if [ -z $ARG_GITHUB_TOKEN ]; then
    warning "When run for the first time, generate a GitHub API token using:\n"
		warning "    $SCRIPT_NAME -t [TOKEN]\n"
    warning "See README.md for further instructions."
    exit 1
  else
		heading 'GitHub'
    $CMD "$API_GITHUB/users/$ARG_USERNAME?access_token=$ARG_GITHUB_TOKEN" \
      | sed -nE 's#^.*"email": "([^"]+)",.*$#\1#p'
  fi

  heading 'npm'
  if hash jq 2>/dev/null; then
    $CMD "$API_NPM/-/user/org.couchdb.user:$ARG_USERNAME" | jq -r '.email'
  else
    warning "Install jq to scan npm users."
  fi

  heading 'Recent Commits'
  $CMD "$API_GITHUB/users/$ARG_USERNAME/events" \
    | sed -nE 's#^.*"(email)": "([^"]+)",.*$#\2#p' \
    | sort -u

  heading 'Recent Repository Activity'
  if [ -z $ARG_REPOSITORY ]; then
    # Get first repository if not specified
    ARG_REPOSITORY="$($CMD "$API_GITHUB/users/$ARG_USERNAME/repos?type=owner&sort=updated" \
      | sed -nE 's#^.*"name": "([^"]+)",.*$#\1#p' \
      | head -n1)"
  fi

  # Find all commits against the repository
  $CMD "$API_GITHUB/repos/$ARG_USERNAME/$ARG_REPOSITORY/commits" \
    | sed -nE 's#^.*"(email|name)": "([^"]+)",.*$#\2#p'  \
    | pr -2 -at \
    | sort -u
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
      -h|-?|--help)
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
      # Assume username, repository, and token.
      *)
      ARG_USERNAME=$1
      ARG_REPOSITORY=$2
      ARG_GITHUB_TOKEN=$3
      # Skip arguments
      shift && shift && shift
      ;;
    esac
  done
  set -- "${POSITIONAL[@]}"
}

show_usage() {
	printf "Usage: $SCRIPT_NAME username [repository]\n" >&2
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

