# AdGuard Home on k8s

Two [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) instances answer DNS on port 53 of pi02 and pi03. Change settings at `https://adguard.home.arpa`, on the origin (`adguard-home-0`). Every 10 minutes [adguardhome-sync](https://github.com/bakito/adguardhome-sync) copies them to the replica (`adguard-home-1`), so changes made on the replica do not last.

Each instance has its own query log and statistics. The web UI shows the origin's. To see the replica's:

```sh
kubectl -n adguard port-forward adguard-home-1 3000
```

## Install

[Argo CD](../README.md#argo-cd) deploys this chart from `master`, starting from `cluster/manifests/argocd-adguard-home.yaml`:

```sh
mise bootstrap remote pi01
```

The pods come up on the first-run wizard, and `adguardhome-sync` waits for its Secret. Then, once:

```sh
mise run cluster:adguard-setup
```

It asks for a password, creates the origin's `admin`, stores the credentials in a Secret, and sends `home.arpa` and reverse lookups of the LAN to the router. `adguardhome-sync` then sets up the replica by itself.

Finally, on the router:

1. Add a static DNS name, `adguard.home.arpa`, pointing to a node.
2. Make DHCP hand out `192.168.100.4` and `192.168.100.5` as the DNS servers.

Check that both instances answer before you change DHCP:

```sh
dig @192.168.100.4 pbx.home.arpa
dig @192.168.100.5 example.com
```

## Upgrade

Change `values.yaml` and push to `master`. Pods restart one at a time, the replica first, so one instance keeps answering.

If a node stays down, its pod waits for it, as its volumes live there. Clients fall back on the other instance. While the origin is down, `adguardhome-sync` does nothing and the replica keeps its settings.

## Rebuild the origin

`adguardhome-sync` never sets up the origin, so a lost origin stays on the first-run wizard and cannot wipe the replica. Do not run `cluster:adguard-setup` for it, as the empty settings would reach the replica. Copy the replica's settings back instead:

```sh
kubectl -n adguard exec adguard-home-1 -- cat /opt/adguardhome/conf/AdGuardHome.yaml |
  kubectl -n adguard exec -i adguard-home-0 -- sh -c 'cat >/opt/adguardhome/conf/AdGuardHome.yaml'
kubectl -n adguard delete pod adguard-home-0
```

## Uninstall

Remove `cluster/manifests/argocd-adguard-home.yaml` from the repository and from `/var/lib/rancher/k3s/server/manifests/` on pi01, point the router's DHCP back at the router, then delete the Application. AdGuard Home keeps running until its resources are deleted too. Deleting the namespace deletes the data.

```sh
kubectl delete application -n argocd adguard-home
kubectl delete namespace adguard
```
