#!/usr/bin/env bash
#
# ptyxis replaced gnome-terminal in Alma 10
#
set -euo pipefail

echo "[ptyxis] seeding default profile via system dconf db"

UUID=$(uuidgen | tr -d '-')

# dconf load requires a live user D-Bus session to write correctly -- there
# isn't one during kickstart install (root, no session bus). Writing a
# system dconf db default instead works with no session required: it
# compiles to a filesystem-level default that applies the moment dev's
# session starts, and dev can still override any of it later via Ptyxis's
# own Preferences UI, since user changes take precedence over this default.

mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/01-ptyxis << EOF
[org/gnome/Ptyxis]
audible-bell=false
default-profile-uuid='$UUID'
font-name='Red Hat Mono Bold 14 @wght=700'
interface-style='dark'
profile-uuids=['$UUID']
use-system-font=false
window-size=(uint32 249, uint32 31)

[org/gnome/Ptyxis/Profiles/$UUID]
bold-is-bright=true
label='alma10-dev'
palette='gnome-high-contrast'
EOF

dconf update

echo "[ptyxis] default profile seeded (uuid: $UUID)"
