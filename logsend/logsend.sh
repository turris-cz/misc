#!/bin/busybox sh

# Configuration
set -ex

# List of daemon names. Separate by \|, it's put into the regular expression.
DAEMONS='ucollect\|updater\|watchdog\|oneshot'
# Where to put the logs (don't forget the question mark at the end)
BASEURL='https://api.turris.cz/logsend/upload.cgi?'
RID="$(atsha204cmd serial-number)"
CERT="/etc/ssl/startcom.pem"
TMPFILE="/tmp/logsend.tmp"
BUFFER="/tmp/logsend.buffer"
trap 'rm -f "$TMPFILE" "$BUFFER"' EXIT ABRT QUIT TERM

# Don't load the server all at once. With NTP-synchronized time, and
# thousand clients, it would make spikes on the CPU graph and that's not
# nice.
sleep $(( $(tr -cd 0-9 </dev/urandom | head -c 8 | sed -e 's/^0*//' ) % 120 ))

cp /tmp/logs.last.sha1 "$TMPFILE" || true
# Grep regexp: Month date time hostname daemon
# tail ‒ limit the size of upload
(
	cat /var/log/messages.1 || true
	cat /var/log/messages
) | \
	/usr/bin/whatsnew "$TMPFILE" | \
	grep "^[^ ][^ ]* *[a-z][a-z]* *\($DAEMONS\)\(\[[0-9]*\]\|\):" | \
	tail -n 10000 >"$BUFFER"

(
	atsha204cmd file-challenge-response <"$BUFFER"
	cat "$BUFFER"
) | curl --compress --cacert "$CERT" -T - "$BASEURL$RID" -X POST
mv "$TMPFILE" /tmp/logs.last.sha1
