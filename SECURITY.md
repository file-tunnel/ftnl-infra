# Security policy

Report vulnerabilities through GitHub Security Advisories.

Do not commit Kubernetes `Secret` resources, cloud credentials, registry
tokens, tunnel capabilities, presigned URLs, or production object keys.
External Secrets should reference the cluster's configured secret store.

The bootstrap all-zero image digests are deliberately undeployable. Promote
only tested immutable digests.
