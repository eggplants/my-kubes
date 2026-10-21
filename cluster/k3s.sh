#!/usr/bin/env bash
# The bootstrap task: runs on every `mise bootstrap`, so it must be safe to repeat.
# Installs k3s $K3S_VERSION as $K3S_ROLE, and restarts it after [bootstrap.files] changes config.yaml.
set -euo pipefail
die() {
  echo "k3s.sh: $*" >&2
  exit 1
}

case "${K3S_ROLE:-}" in
  server) unit=k3s other=k3s-agent ;;
  agent) unit=k3s-agent other=k3s ;;
  *) die "K3S_ROLE is not set; give the host mise_env = [\"server\"] or [\"agent\"] in ../mise.toml" ;;
esac
config=/etc/rancher/k3s/config.yaml
stamp=/var/lib/rancher/k3s/mise-config.stamp

for p in cgroup_memory=1 cgroup_enable=memory; do
  grep -qw "$p" /boot/firmware/cmdline.txt ||
    die "add 'cgroup_memory=1 cgroup_enable=memory' to /boot/firmware/cmdline.txt and reboot"
done
[[ ! -e "/etc/systemd/system/$other.service" ]] ||
  die "$other.service is installed on this $K3S_ROLE; run 'mise run cluster:reset $(hostname)' on the Mac first"
[[ "$K3S_ROLE" == server || -s /etc/rancher/k3s/token ]] ||
  die "/etc/rancher/k3s/token is missing; run 'mise run cluster:token' on the Mac first"

current="$(k3s --version 2>/dev/null | awk 'NR == 1 { print $3 }')" || true
if [[ ! -e "/etc/systemd/system/$unit.service" || "$current" != "$K3S_VERSION" ]]; then
  echo "k3s.sh: installing k3s $K3S_VERSION ($K3S_ROLE, was ${current:-none})"
  curl -sfL https://get.k3s.io | sudo env INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="$K3S_ROLE" sh -
  sudo touch "$stamp"
elif [[ "$config" -nt "$stamp" ]]; then
  echo "k3s.sh: $config changed; restarting $unit"
  sudo systemctl restart "$unit"
  sudo touch "$stamp"
fi
