# Security policy

Report vulnerabilities through GitHub Security Advisories.

Do not commit Kubernetes `Secret` resources, cloud credentials, registry
tokens, tunnel capabilities, presigned URLs, or production object keys.
External Secrets should reference the cluster's configured secret store.

Provider values may be committed only as SOPS ciphertext under
`env/enc/*.env.enc`. Decrypted `env/dec/`, age private keys, GitHub environment
secrets, and generated Kubernetes Secret data must never be committed or
printed. Enter rotated credentials through `just edit <environment>` so values
do not pass through command arguments, patches, tickets, or chat transcripts.

The bootstrap all-zero image digests are deliberately undeployable. Promote
only tested immutable digests.
