# README
## Session03 - Exercise-01

All the heavy lifting is done in ./command.bash
Executing this script will:

- Generate certificates for 3 users, each belonging to different groups.
- Generate the proper kubeconfig files for all 3 of them.
- Set permissions (roles and rolebindings) per namespace and/or groups
- Set resource quotas and limits for the namespaces


Generated files:

certificates/USER.csr: Certificate Signing Request for each user
certificates/USER.crt: Signed certificate by Kubernetes CA for each user
certificates/USER.key: Private key for each user
USER-csr.yaml: CertificateSigningRequest resources
kubecfg-USER: kubecfg files for each user
