# My kubes

| Host | Address | Role |
|---|---|---|
| pi01 | pi01.home.arpa (192.168.100.9) | k3s server (runs [MikoPBX](./mikopbx)) |
| pi02 | pi02.home.arpa (192.168.100.4) | k3s agent |
| pi03 | pi03.home.arpa (192.168.100.5) | k3s agent |
| pi04 | pi04.home.arpa (192.168.100.6) | k3s agent |

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

[Argo CD](https://argo-cd.readthedocs.io/) keeps [MikoPBX](./mikopbx) in sync with `master`. It is not exposed outside the cluster; to open the UI at `https://localhost:18080` as `admin`:

```bash
# initial password
ssh eggplants@pi01.home.arpa "sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'" | base64 -d

ssh -L 18080:localhost:18080 eggplants@pi01.home.arpa sudo k3s kubectl -n argocd port-forward svc/argocd-server 18080:443
```

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
