#!/bin/bash
# shell-ini-parser (shini) - compatible INI library for sh
# Modified (simplified) version (no support for callbacks or writing). Needs bash version 3 or newer
#
# This code is released freely under the MIT license - see the shipped LICENSE document.
# For the latest version etc, please see https://github.com/wallyhall/shini
#
# Simplified usage (note the second parameter is optional):
# shini_parse_section "filename.ini" ["section_name"]
#
#
# The MIT License (MIT)
# 
# Copyright (c) 2014 wallyhall (Matthew Hall)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#


shini_regex_match()
{
    [[ "$1" =~ $2 ]] && return 0 || return 1
}

shini_regex_replace()
{
    [[ "$1" =~ $2 ]] && shini_retval=${BASH_REMATCH[1]} || shini_retval="$1"
    return 0
}

# @param inifile Filename of INI file to parse
# @param section Section to parse (or empty string for entire file)
# @param postfix Function postfix for callbacks (optional)
# @param extra Extra argument for callbacks (optional)
shini_parse_section()
{
    RX_KEY='[a-zA-Z0-9_\-\.]'
    RX_VALUE="[^;\"]"
    RX_SECTION='[a-zA-Z0-9_\-]'
    RX_WS='[ 	]'
    RX_QUOTE='"'
    RX_HEX='[0-9A-F]'
    POSTFIX=''
    SKIP_TO_SECTION=''
    EXTRA1=''
    EXTRA2=''
    EXTRA3=''
    SECTION_FOUND=-1
	
	if [ $# -ge 2 ] && [ ! -z "$2" ]; then
        SKIP_TO_SECTION="$2"
    fi
	
    if [ $# -ge 3 ] && [ ! -z "$3" ]; then
        POSTFIX="_$3"
    fi
	
    if [ $# -ge 4 ] && ! [ -z "$4" ]; then
        EXTRA1="$4"
    fi
	
    if [ $# -ge 5 ] && [ ! -z "$5" ]; then
        EXTRA2="$5"
    fi
	
    if [ $# -ge 6 ] && [ ! -z "$6" ]; then
        EXTRA3="$6"
    fi

    if [ $# -lt 1 ]; then
        printf 'Argument 1 needs to specify the INI file to parse.\n' 1>&2
        exit 254
    fi
    INI_FILE="$1"

    if [ ! -r "$INI_FILE" ]; then
        printf 'Unable to read INI file:\n  `%s`\n' "$INI_FILE" 1>&2
        exit 253
    fi

    # Iterate INI file line by line
    LINE_NUM=0
    SECTION=''
    while read LINE || [ -n "$LINE" ]; do  # -n $LINE catches final line if not empty
        # Check for new sections
        if shini_regex_match "$LINE" "^${RX_WS}*\[${RX_SECTION}${RX_SECTION}*\]${RX_WS}*$"; then
            shini_regex_replace "$LINE" "^${RX_WS}*\[(${RX_SECTION}${RX_SECTION}*)\]${RX_WS}*$" "\1"
            SECTION=$shini_retval

            if [ "$SKIP_TO_SECTION" != '' ]; then
                # stop once specific section is finished
                [ $SECTION_FOUND -eq 0 ] && break;
                
                # mark the specified section as found
                [ "$SKIP_TO_SECTION" = "$SECTION" ] && SECTION_FOUND=0;
            fi

            continue
        fi
        
        # Skip over sections we don't care about, if a specific section was specified
        [ "$SKIP_TO_SECTION" != '' ] && [ $SECTION_FOUND -ne 0 ] && continue;
		
        # Check for new values
        if shini_regex_match "$LINE" "^${RX_WS}*${RX_KEY}${RX_KEY}*${RX_WS}*="; then
            shini_regex_replace "$LINE" "^${RX_WS}*(${RX_KEY}${RX_KEY}*)${RX_WS}*=.*$"
            KEY=$shini_retval
            
            shini_regex_replace "$LINE" "^${RX_WS}*${RX_KEY}${RX_KEY}*${RX_WS}*=${RX_WS}*${RX_QUOTE}{0,1}(${RX_VALUE}*)${RX_QUOTE}{0,1}(${RX_WS}*\;.*)*$"
            VALUE=$shini_retval
			
            if shini_regex_match "$LINE" "^0x${RX_HEX}${RX_HEX}*$"; then
                VALUE=$(printf '%d' "$VALUE")
            fi
			
            continue
        fi
		
        # Announce parse errors
        if [ "$LINE" != '' ] &&
          shini_regex_match "$LINE" "^${RX_WS}*;.*$" &&
          shini_regex_match "$LINE" "^${RX_WS}*$"; then
          printf 'Unable to parse line %d:\n  `%s`\n' $LINE_NUM "$LINE"
        fi
		
        LINE_NUM=$((LINE_NUM+1))
    done < "$INI_FILE"
}
