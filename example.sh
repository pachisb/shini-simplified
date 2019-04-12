#!/bin/bash
# shini usage example (from https://github.com/wallyhall/shini)

# Include library
# For this reason, you should locate shell-ini-parser.sh somewhere super unwritable by world.
. "$(dirname "$0")/shell-ini-parser.sh"

# Parse
printf "Parsing...\n\n"
shini_parse_section "example.ini"
printf "\nComplete.\n"
