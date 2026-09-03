#!/usr/bin/env bash
set -euo pipefail

echo "[vscode] adding Microsoft dnf repo"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<'EOF' > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf install -y code

echo "[vscode] seeding default user settings (color theme)"
settings_dir=/home/dev/.config/Code/User
mkdir -p "$settings_dir"
cat <<'EOF' > "$settings_dir/settings.json"
{
    "workbench.colorTheme": "Light 2026",
    "security.workspace.trust.enabled": false
}
EOF
chown -R dev:dev /home/dev/.config

echo "[vscode] installed: $(code --version | head -n1)"
