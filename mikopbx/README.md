# MikoPBX on k8s

After you install, see `https://pbx.home.arpa`, a static DNS name on the router that points to the node. `http://<host>:8080` and `https://<host>:8443` stay open, as the pod uses the host network.

![top](https://github.com/user-attachments/assets/f9e31955-57eb-4eac-8159-7abb16e1d3a9)

## Install

[Argo CD](../README.md#argo-cd) deploys this chart from `master`. `wwwUser` in `values.yaml` must match the uid and gid of `www-user` on the node.

## Upgrade

Change `values.yaml` and push to `master`. Argo CD applies it within a few minutes, and any change to the pod restarts MikoPBX at once, cutting calls in progress.

The pod uses the host network, so Asterisk advertises the node's own LAN and Tailscale addresses in SDP. It runs without `NET_ADMIN`: MikoPBX's firewall and fail2ban cannot change the node's iptables, so the firewall settings in the web UI have no effect. SIP is meant to be reached only over the tailnet.

## Uninstall

Remove `cluster/manifests/argocd-mikopbx.yaml` from the repository and from `/var/lib/rancher/k3s/server/manifests/` on pi01, then delete the Application. MikoPBX keeps running until its resources are deleted too. Deleting the PVCs deletes the PBX's data.

```sh
kubectl delete application -n argocd mikopbx
kubectl delete deployment/mikopbx service/mikopbx-service pvc/mikopbx-cf-pvc pvc/mikopbx-storage-pvc
```
