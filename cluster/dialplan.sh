#!/usr/bin/env bash
# Sync dialplan/*.conf to MikoPBX's dialplan applications through its REST API.
#
# Runs on the server node: MikoPBX uses the host network there and accepts API
# calls from 127.0.0.1 without authentication. dialplan/<extension>.conf holds the
# application logic, after optional "; name|description|hint|type: <value>" header
# lines. Applications are matched by extension and only changed ones are written;
# ones that exist only in MikoPBX are reported, never deleted.
set -euo pipefail
shopt -s nullglob

api=http://127.0.0.1:8080/pbxcore/api/v3/dialplan-applications
dir="$(dirname "$0")/dialplan"

# call METHOD URL [JSON]: print the reply's data, or fail with its messages
call() {
  local reply
  reply="$(curl -fsS -X "$1" -H 'Content-Type: application/json' ${3:+--data-binary "$3"} "$2")"
  if ! jq -e .result <<<"$reply" >/dev/null; then
    echo "dialplan: $1 $2: $(jq -c .messages <<<"$reply")" >&2
    return 1
  fi
  jq .data <<<"$reply"
}

# load FILE: print the application the file describes
load() {
  jq -Rs --arg ext "$(basename "$1" .conf)" '
    split("\n") as $lines
    | ([$lines | to_entries[] | select(.value | test("^; (name|description|hint|type): ?") | not)][0].key
       // ($lines | length)) as $n
    | reduce ($lines[:$n][] | capture("^; (?<k>[a-z]+): ?(?<v>.*)$")) as $h
        ({extension: $ext, name: $ext, description: "", hint: "", type: "plaintext"}; .[$h.k] = $h.v)
    | .applicationlogic = ($lines[$n:] | join("\n") | sub("^\n+"; "") | sub("\n+$"; ""))
  ' "$1"
}

if ! listed="$(call GET "$api")"; then
  echo "dialplan: MikoPBX API is not reachable; skipped" >&2
  exit 0
fi

# the list omits the logic, so read each application
current='{}'
for id in $(jq -r '.[].id' <<<"$listed"); do
  current="$(jq --argjson a "$(call GET "$api/$id")" '. + {($a.extension): $a}' <<<"$current")"
done

wanted=()
for file in "$dir"/[!.]*.conf; do
  app="$(load "$file")"
  ext="$(jq -r .extension <<<"$app")"
  name="$(jq -r .name <<<"$app")"
  wanted+=("$ext")
  cur="$(jq --arg e "$ext" '.[$e]' <<<"$current")"
  if [[ "$cur" == null ]]; then
    call POST "$api" "$app" >/dev/null
    echo "dialplan: created $ext ($name)"
  elif jq -e -n --argjson c "$cur" --argjson w "$app" \
    '["name", "description", "hint", "type", "applicationlogic"] | all(($c[.] // "") == $w[.])' >/dev/null; then
    echo "dialplan: $ext unchanged"
  else
    id="$(jq -r .id <<<"$cur")"
    call PUT "$api/$id" "$(jq --arg id "$id" '. + {id: $id}' <<<"$app")" >/dev/null
    echo "dialplan: updated $ext ($name)"
  fi
done

jq -r --args '. as $c | keys - $ARGS.positional | .[] | "dialplan: \(.) (\($c[.].name)) exists only in MikoPBX; left as is"' \
  "${wanted[@]}" <<<"$current"
