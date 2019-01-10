# github-email

Retrieve a GitHub user's email even if it's not public. 
Pulls info from Github user, NPM, activity commits, owned repo commit activity.

![image](https://cloud.githubusercontent.com/assets/39191/7485758/6992dc62-f34f-11e4-9af0-3d0f292f6139.png)

# Requirements

Install the following software packages:

* [jq](https://stedolan.github.io/jq/download/)

# Installation

Install the script using any method described in this section.

## npm

Install the script using [npm](https://www.npmjs.com/) as follows:

```sh
npm install --global github-email
```

## wget

Install the script for the local account as follows:

```sh
mkdir -p $HOME/bin
wget https://raw.githubusercontent.com/paulirish/github-email/master/github-email.sh -O $HOME/bin/github-email
chmod +x $HOME/bin/github-email
```

# Token

Provide an [authenticated API](https://git.io/vxctz) request to retrieve
an email as follows:

1. Visit https://github.com/settings/tokens/new?description=github-email
1. Click __Generate Token__.
1. Copy the token.
1. Run: `github-email -t {token}`

This will save a copy of the token in `$HOME/.ghtoken`.

# Usage

Example usages include:

```sh
github-email user 
```

