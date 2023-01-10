#!/usr/bin/env bash

set -euo pipefail

## This script will generate a Github Token from an App, which will be used in semantic-release.

## Variables for the script
appId="$GITHUB_APP_ID"
secret="$(echo $GITHUB_PRIVATE_KEY | base64 -d)"
repo="Gusto/apollo-federation-ruby"

header='{ "typ": "JWT", "alg": "RS256" }'
payload="{ \"iss\": \"$appId\" }"

## Make a JWT payload to access the API as the App
payload=$(
    echo "${payload}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num - 15
    | .exp=($time_num + 60 * 5)
    '
)

## funcations for JWT signing
b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }
rs_sign() { openssl dgst -binary -sha256 -sign <(printf '%s\n' "$1"); }

## Sign the JWT
signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
sig=$(printf %s "$signed_content" | rs_sign "$secret" | b64enc)

## Get the Installation ID
installation_id=$(jq .id <<< "$(curl --location -g -s \
--request GET "https://api.github.com/repos/${repo}/installation" \
--header 'Accept: application/vnd.github.machine-man-preview+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

## Get a token for the installation, but not scoped to a repo
unscoped_token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

## Get the repo ID
repo_id=$(jq .id <<< "$(curl -g -s \
-H "Accept: application/vnd.github.v3+json" \
--header "Authorization: token $unscoped_token" \
"https://api.github.com/repos/$repo")")

## Finally geneate the token from the Installation ID that is scopped to juse the repo
token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}" \
-d "{\"repository_ids\":[$repo_id]}" )")

## Export the token from semantic-release
export GH_TOKEN="$token"

## Exec into semmantic release w/ GH_TOKEN set
exec npx semantic-release
