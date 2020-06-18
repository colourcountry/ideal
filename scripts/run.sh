#!/bin/bash

if [[ -z "$1" ]]
then
  echo "Usage: run.sh <cart-filename>"
  exit 1
fi

love .. "$1"
