#!/bin/bash

if [[ -z "$1" ]]
then
  echo "Usage: wipe_memory.sh <cart-filename>"
  exit 1
fi

rm -v ~/.local/share/love/data/memory/$(basename "$1")
