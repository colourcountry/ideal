#!/bin/bash

love .. carts/tests/help.n83 2>&1 | sed -n '/^# /,$p' | tee ../doc/keywords.md
