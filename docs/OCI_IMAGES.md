# OCI registry and Lambda image contract

Policy: <https://github.com/ORESoftware/my-ai/blob/main/AGENTS.md>.

## Authorities

This repository consumes two immutable, merged Zed Infra authorities:

- registry provisioning modules: `zed-pkg/zed-infra@698c675f57fd70ebe24a8a08f963599c4c84fa5a`;
- BuildKit/Lambda publisher: `zed-pkg/zed-infra@e0454f5d0d8c970dfa206595a48eda5ead382544`, Git blob `8490ce53434410192c750b10d17fe122e9df30be`.

The organization-local Terraform adapter keeps ECR, Google Artifact Registry, Azure Container Registry, and Cloudflare R2 independent and disabled by default. Crossplane examples remain unapplied until provider configs, accounts, regions, IAM, retention, cost, and rollback are reviewed.

## Image contract

`scripts/oci/build-and-push.sh` verifies the exact publisher blob before execution. Configuration and credentials are environment/credential-helper inputs; command arguments are rejected.

Portable service images may publish a `linux/amd64,linux/arm64` index. AWS Lambda images must set `IMAGE_KIND=lambda` and exactly one platform (`linux/amd64` or `linux/arm64`). Invalid Lambda indexes fail before authentication or Docker side effects. `PUSH=false` loads one local platform without registry login.

Use `docker/Dockerfile.rust-service`, `docker/Dockerfile.rust-lambda`, or `docker/Dockerfile.node-lambda` for repository roots, `src/lambda`, or sibling `*-lambda` repositories. The Rust Lambda runtime retains only the `bootstrap` executable.

R2 is an OCI archive/disaster-recovery destination after a successful push to ECR, GAR, ACR, Docker Hub, or another Distribution endpoint. It is not a direct pull registry for Lambda, Cloud Run, Kubernetes, Docker, or containerd.

## Validation

```bash
bash -n scripts/oci/build-and-push.sh
OCI_TOOLKIT_VERIFY_ONLY=true scripts/oci/build-and-push.sh
terraform -chdir=terraform/modules/oci-registries fmt -check
terraform -chdir=terraform/modules/oci-registries init -backend=false -input=false
terraform -chdir=terraform/modules/oci-registries validate
```

Live image publication and Terraform/Crossplane apply remain protected-environment operations; this repository change performs neither.
