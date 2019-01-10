
# Authenticated Request

Provide an [authenticated API](https://git.io/vxctz) request to retrieve
an email as follows:

1. Visit https://github.com/settings/tokens/new?description=github-email
1. Click __Generate Token__.
1. Copy the token.
1. Run: `github-email -t {token}`

This will save a copy of the token in `$HOME/.ghtoken`.

