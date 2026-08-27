#!/bin/bash

set -Eeuo pipefail

export LC_ALL=C

# SCRIPT_SELF="$(realpath "${BASH_SOURCE[0]}")"
# shellcheck disable=SC2034 # appears unused
# SCRIPT_DIR=$(dirname "${SCRIPT_SELF}")
# SCRIPT_FILE=$(basename "${SCRIPT_SELF}")
# SCRIPT_NAME=$(basename -s .bash "$(basename -s .sh "${SCRIPT_FILE}")")
# SCRIPT_EXT=${SCRIPT_FILE#${SCRIPT_NAME}}

PACKAGE_NAME=xcertcheck

# 💁✅📦🔎🌎🚽💥👶📁👍🔧⚠ 🔐👿👷🗑☑🧩🔥🙏⌛
log() {
	echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}
# ifIsSet() {
# 	[[ ${!1-x} == x ]] && return 1 || return 0
# }
ifNotSet() {
	[[ ${!1-x} == x ]] && return 0 || return 1
}

cleanup_display_cleanup=true
cleanup_display_error=true
die() {
	local msg=$1
	local exit_code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
	log "$msg"
	# [[ $exit_code -ne 0 ]] && log "💥 Error!"
	cleanup_display_error=false
	exit "$exit_code"
}
# shellcheck disable=SC2329 # (info): This function is never invoked. Check usage (or ignored if invoked indirectly).
cleanup() {
	exit_code=$?
	trap - SIGINT SIGTERM ERR EXIT
	[[ $cleanup_display_cleanup = true ]] && log "🚽 cleanup"
	# NOTE: clean custom files, ...

	[[ $cleanup_display_error = true ]] && [[ $exit_code -ne 0 ]] && log "💥 Error!"
	exit "$exit_code"
}
trap cleanup SIGINT SIGTERM ERR EXIT

CONFFILE=${1:-/etc/xcertcheck.conf}

# example
# XMAIL=/usr/local/bin/fake-msmtp bash ./xcertcheck.sh 700 xcertcheck.list.txt bozo@kosmev.com
if [ ! -r "${CONFFILE}" ]; then
	log "💥 Config file ${CONFFILE} not found!"
	log ""
	log "Example ${CONFFILE}:"
	log "DOMAINS=/etc/xcertcheck.list.txt"
	log "RECIPIENT=user@example.com"
	log "DAYS=7"
	log "XMAIL=/usr/bin/sendmail"
	log "OPENSSL_TIMEOUT=30"
	log ""
	log "example /etc/xcertcheck.list.txt"
	log "www.danov.pro:443"
	log "www.google.com:443"
	log ""
	die "💥 Pleace, fix configuration!"
fi

# shellcheck disable=SC1090 # (warning): ShellCheck can't follow non-constant source. Use a directive to specify location.
source "${CONFFILE}"

ifNotSet DAYS && die "💥 DAYS not defined!"
ifNotSet DOMAINS && die "💥 DOMAINS not defined!"
ifNotSet RECIPIENT && die "💥 RECIPIENT not defined!"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
	die "💥 Invalid days '${1}'!"
fi
if [ ! -r "${DOMAINS}" ]; then
	die "💥 Domains list file '${DOMAINS}' not found"
fi

ifNotSet OPENSSL_TIMEOUT && OPENSSL_TIMEOUT=10

res=0
log "🔎 Checking if certificates expires in less than ${DAYS} days"
while read -r TARGET; do
	log "🔎 Checking if ${TARGET} expires in less than ${DAYS} days"

	log "⌛ Get certificate from ${TARGET}"
	cert=$(: | timeout "${OPENSSL_TIMEOUT}" openssl s_client -connect "${TARGET}" -servername "${TARGET}" 2>/dev/null || true)
	if [ -z "$cert" ]; then
		log "⚠ No certificate for ${TARGET}"
		# FIXME: send mail
		continue
	fi

	cert_exp=$(echo "${cert}"| openssl x509 -text | grep 'Not After' | awk '{print $4,$5,$7}')
	# log "🙏 Certificate for ${TARGET} expire date ${cert_exp}"
	expirationdate=$(date -d "${cert_exp}" '+%s' 2>/dev/null || true)
	if [ -z "$expirationdate" ]; then
		log "⚠ No expiratin date in certificate for ${TARGET}"
		# FIXME: send mail
		continue
	fi
	expdate=$(date -d @"${expirationdate}" '+%Y-%m-%d')
	in7days=$(($(date +%s) + (86400*DAYS)))
	if [ "${in7days}" -gt "${expirationdate}" ]; then
		log "⚠ Certificate for ${TARGET} expires in less than ${DAYS} days, on ${expdate}"

		# shellcheck disable=SC2086 # (info): Double quote to prevent globbing and word splitting.
		echo -e "Subject: Certificate expiration warning for ${TARGET}: ${expdate}\n" \
			"\nCertificate expiration warning for ${TARGET}: expires in less than ${DAYS} days, on ${expdate}\n" \
			| ${XMAIL} ${RECIPIENT}
		res=1
	else
		log "👍 Certificate for ${TARGET} expires on ${expdate}"
	fi
done < "${DOMAINS}"

die "✅ Done, result ${res}" ${res}
