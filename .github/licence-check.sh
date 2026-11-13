#!/bin/sh
# The README's "Selling with licences" commands, end to end, with throwaway keys in <folder>:
# key generate, licence sign / verify (any machine, one machine), key rotate, licence resign.
# Used by .github/workflows/check.yml on the template's repository; never point it at a real key.
set -eu
tmp="$1"
omnihub="$(pwd)/vendor/bin/omnihub"
url=https://example.github.io/hub
"$omnihub" key generate "$tmp/old.key" > "$tmp/generate.txt"
public=$("$omnihub" key public "$tmp/old.key")
cat > "$tmp/hub.yaml" <<YAML
name: Licence check
url: $url
licensing:
  publicKey: "$public"
licensed:
  - { package: com.example.tool, get: "https://shop.example.org/tool" }
packages: []
YAML
cd "$tmp"
"$omnihub" check hub.yaml --url="$url"
token=$("$omnihub" licence sign old.key --package com.example.tool --licensee "Ada <ada@example.org>" --days 365 --log sales.jsonl)
"$omnihub" licence verify hub.yaml "$token" --package com.example.tool
"$omnihub" licence verify "$token" --hub hub.yaml --package com.example.other && exit 1 || echo "another package: refused, as it should be"
id=$(printf %s "a machine" | sha256sum | cut -c1-64)
bound=$("$omnihub" licence sign old.key --package com.example.tool --licensee "Bob" --machine-hash "$id" --valid-until 2099-01-01 --log sales.jsonl)
"$omnihub" licence verify hub.yaml "$bound" --package com.example.tool --machine-hash "$id"
"$omnihub" key generate new.key > /dev/null
"$omnihub" key rotate old.key new.key --previous-until 2099-01-01 > rotate.txt
grep -q 'previousKeyValidUntil: 4070908800' rotate.txt
"$omnihub" licence resign new.key sales.jsonl --registry "$url" > resigned.tsv
test "$(wc -l < resigned.tsv)" -eq 2
echo "licence commands: OK"
