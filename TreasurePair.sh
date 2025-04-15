#!/bin/sh
echo -ne '\033c\033]0;TreasurePair\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/TreasurePair.x86_64" "$@"
