# README
## Session03 - Exercise-02

Executing ./command.sh will deploy wordpress with a mariadb backend and apply a network policy that avoids mariadb to be accessed from anywhere else than the pods labeled with "tier: frontend".

### Notes
Although the NetworkPolicy was applied without any problem, connections were still allowed from containers not belonging to the frontend. The network plugin being used in this Kubernetes cluster is Weave. The logs of the weave-npc container did not show any attempt of blocking traffic whatsoever.

Nonetheless, the corresponding IPTABLES rules were present on the Kubernetes node, which confirmed that the network-controller of weave was working correctly and applying the policies as expected.

Executing the weave status tool didn't report any issues either:
kubectl exec -n kube-system weave-net-tr2q4 -c weave -- /home/weave/weave --local status

Eventually I got it working by upgrading the weave plugin to the latest available version:

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
