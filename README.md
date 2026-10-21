# My kubes

| Host | Address | Role |
|---|---|---|
| pi01 | 192.168.100.9 | k3s server (runs [MikoPBX](./mikopbx)) |
| pi02 | pi02.local | k3s agent |
| pi03 | pi03.local | k3s agent |
| pi04 | pi04.local | k3s agent |

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
