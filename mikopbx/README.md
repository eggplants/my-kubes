# MikoPBX on k8s

After you install, see `https://<host>:8080`.

![top](https://github.com/user-attachments/assets/f9e31955-57eb-4eac-8159-7abb16e1d3a9)

## Install

```sh
./install.sh
```

## Upgrade

```sh
helm upgrade mikopbx . --reset-then-reuse-values
```

The pod uses the host network, so Asterisk advertises the node's own LAN and Tailscale addresses in SDP. It runs without `NET_ADMIN`: MikoPBX's firewall and fail2ban cannot change the node's iptables, so the firewall settings in the web UI have no effect. SIP is meant to be reached only over the tailnet.

## Uninstall

```sh
helm uninstall mikopbx
```
