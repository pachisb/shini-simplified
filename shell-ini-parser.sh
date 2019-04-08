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
# @param section Section to parse (or empty string for default parsing of the entire file)
# @param prefix Prefix to use on variable names (or empty string for default: "SHINI")
shini_parse_section()
{
    RX_KEY='[a-zA-Z0-9_\-\.]'
    RX_VALUE="[^;\"]"
    RX_SECTION='[a-zA-Z0-9_\-]'
    RX_WS='[ 	]'
    RX_QUOTE='"'
    RX_HEX='[0-9A-F]'
    SHINI_SKIP_TO_SECTION=''
    SHINI_PREFIX='SHINI'
    SHINI_SECTION_FOUND=-1
	
	if [ $# -ge 2 ] && [ ! -z "$2" ]; then
        SHINI_SKIP_TO_SECTION="$2"
    fi
	
    if [ $# -ge 3 ] && [ ! -z "$3" ]; then
        SHINI_PREFIX="${3^^}"  # Converted to uppercase
    fi
	
    if [ $# -lt 1 ]; then
        printf 'Argument 1 needs to specify the INI file to parse.\n' 1>&2
        exit 254
    fi

    if [ ! -r "$1" ]; then
        printf 'Unable to read INI file:\n  `%s`\n' "$1" 1>&2
        exit 253
    fi

    # Iterate INI file line by line
    SHINI_LINE_NUM=0
    SHINI_SECTION=''
    while read SHINI_LINE || [ -n "$SHINI_LINE" ]; do  # -n $SHINI_LINE catches final line if not empty
        # Check for new sections
        if shini_regex_match "$SHINI_LINE" "^${RX_WS}*\[${RX_SECTION}${RX_SECTION}*\]${RX_WS}*$"; then
            shini_regex_replace "$SHINI_LINE" "^${RX_WS}*\[(${RX_SECTION}${RX_SECTION}*)\]${RX_WS}*$" "\1"
            SHINI_SECTION=$shini_retval

            if [ "$SHINI_SKIP_TO_SECTION" != '' ]; then
                # stop once specific section is finished
                [ $SHINI_SECTION_FOUND -eq 0 ] && break;
                
                # mark the specified section as found
                [ "$SHINI_SKIP_TO_SECTION" = "$SHINI_SECTION" ] && SHINI_SECTION_FOUND=0;
            fi

            continue
        fi
        
        # Skip over sections we don't care about, if a specific section was specified
        [ "$SHINI_SKIP_TO_SECTION" != '' ] && [ $SHINI_SECTION_FOUND -ne 0 ] && continue;
		
        # Check for new values
        if shini_regex_match "$SHINI_LINE" "^${RX_WS}*${RX_KEY}${RX_KEY}*${RX_WS}*="; then
            shini_regex_replace "$SHINI_LINE" "^${RX_WS}*(${RX_KEY}${RX_KEY}*)${RX_WS}*=.*$"
            shini_key=$shini_retval
            
            shini_regex_replace "$SHINI_LINE" "^${RX_WS}*${RX_KEY}${RX_KEY}*${RX_WS}*=${RX_WS}*${RX_QUOTE}{0,1}(${RX_VALUE}*)${RX_QUOTE}{0,1}(${RX_WS}*\;.*)*$"
            shini_value=$shini_retval
			
            if shini_regex_match "$SHINI_LINE" "^0x${RX_HEX}${RX_HEX}*$"; then
                shini_value=$(printf '%d' "$shini_value")
            fi

            # Name converted to uppercase with ^^
            echo Setting ${SHINI_PREFIX}__${SHINI_SECTION^^}__${shini_key^^}...
            eval ${SHINI_PREFIX}__${SHINI_SECTION^^}__${shini_key^^}="\"$shini_value\""
			
            continue
        fi
		
        # Announce parse errors
        if [ "$SHINI_LINE" != '' ] &&
          shini_regex_match "$SHINI_LINE" "^${RX_WS}*;.*$" &&
          shini_regex_match "$SHINI_LINE" "^${RX_WS}*$"; then
          printf 'Unable to parse line %d:\n  `%s`\n' $SHINI_LINE_NUM "$SHINI_LINE"
        fi
		
        SHINI_LINE_NUM=$((SHINI_LINE_NUM+1))
    done < "$1" # INI_FILE
}
