# My kubes

| Host | Address | Role |
|---|---|---|
| pi01 | pi01.home.arpa (192.168.100.9) | k3s server |
| pi02 | pi02.home.arpa (192.168.100.4) | k3s agent |
| pi03 | pi03.home.arpa (192.168.100.5) | k3s agent |
| pi04 | pi04.home.arpa (192.168.100.6) | k3s agent |

- MikoPBX: <https://pbx.home.arpa>
- ArgoCD: <https://pi01.home.arpa>

## Apply

```bash
mise bootstrap remote --all --dry-run
mise bootstrap remote --all

mise run cluster:status
```

```
# one host
mise bootstrap remote pi02
```

## Add or rebuild an agent

```bash
# uninstall k3s there and delete its node (asks first)
mise run cluster:reset pi02
# copy pi01's join token to every agent
mise run cluster:token

mise bootstrap remote pi02
```

## Upgrade k3s

The patch version is automatically updated with [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) and [k3s-upgrade](https://github.com/k3s-io/k3s-upgrade) on Sundays from 03:00 to 05:00 JST. 

To move to the next minor, change the channel in `cluster/manifests/system-upgrade-plans.yaml` and `K3S_VERSION` in `cluster/mise.toml`, then:

```bash
mise bootstrap remote pi01
```

## Argo CD

At first:
```bash
mise run cluster:ca > home-ca.crt
mise run cluster:discord-webhook
mise run cluster:argocd-password
```

Then, log in as `admin` at <https://pi01.home.arpa> and change the password.

## MikoPBX dialplan applications

`cluster/dialplan/<extension>.conf` holds each [dialplan application](https://docs.asterisk.org/Configuration/Dialplan/).

```php
; name: welcome
; description: it responds to a call
1,Answer()
...
n,Hangup()
```

```bash
mise bootstrap remote pi01
```

## Notes

`cgroup_memory=1 cgroup_enable=memory` must be in `/boot/firmware/cmdline.txt`.
