#!/usr/bin/env bash

set -euo pipefail

appId="$GITHUB_APP_ID"
secret="$(echo $GITHUB_PRIVATE_KEY | base64 -d)"
repo="Gusto/apollo-federation-ruby"

header='{ "typ": "JWT", "alg": "RS256" }'

payload="{ \"iss\": \"$appId\" }"

payload=$(
    echo "${payload}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num - 15
    | .exp=($time_num + 60 * 5)
    '
)


b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }
rs_sign() { openssl dgst -binary -sha256 -sign <(printf '%s\n' "$1"); }

signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
sig=$(printf %s "$signed_content" | rs_sign "$secret" | b64enc)

installation_id=$(jq .id <<< "$(curl --location -g -s \
--request GET "https://api.github.com/repos/${repo}/installation" \
--header 'Accept: application/vnd.github.machine-man-preview+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

unscoped_token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

repo_id=$(jq .id <<< "$(curl -g -s \
-H "Accept: application/vnd.github.v3+json" \
--header "Authorization: token $unscoped_token" \
"https://api.github.com/repos/$repo")")

token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}" \
-d "{\"repository_ids\":[$repo_id]}" )")

export GH_TOKEN="$token"

exec npx semantic-release
