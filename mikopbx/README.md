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

The pod uses the pod network, not the host network, and publishes web, SSH, SIP, IAX and RTP (`rtp.start`-`rtp.end`) with `hostPort` on the node. Asterisk sees itself at a pod IP, so set the node's address (e.g. `192.168.100.9`) as the external address in MikoPBX's network settings, or calls connect without audio. Keep `sip`, `iaxPort` and `rtp` in `values.yaml` equal to MikoPBX's settings.

## Uninstall

```sh
helm uninstall mikopbx
```
