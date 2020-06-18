#!/bin/bash

love .. carts/tests/help.n83 | sed -n '/^# /,$p'
