set -e

. "$(dirname "$0")/shell-ini-parser.sh"

SECTION=''
[ -n "$1" ] && SECTION=$1

shini_parse_section "tests/php.ini" $SECTION
