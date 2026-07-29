#!/usr/bin/env bash
set -euo pipefail

if command -v kustomize >/dev/null 2>&1; then
  render=(kustomize build)
elif command -v kubectl >/dev/null 2>&1; then
  render=(kubectl kustomize)
else
  echo "kustomize or kubectl is required" >&2
  exit 127
fi

for path in argocd/apps kubernetes/foundation kubernetes/backend kubernetes/portal; do
  "${render[@]}" "$path" >/dev/null
done

if rg -n 'kind: Secret|image: .+:(latest|main|dev)$|type: LoadBalancer' \
  argocd kubernetes interop; then
  echo "plaintext Secrets, mutable image tags, and LoadBalancers are forbidden" >&2
  exit 1
fi

if ! rg -q 'targetRevision: dev' interop/k8s-cluster/README.md 2>/dev/null; then
  # The bootstrap points at this repository's main. Its installation location
  # and the cluster's dev-branch convention are documented in README.
  rg -q 'currently tracks its `dev` branch' README.md
fi

echo "File Tunnel GitOps manifests are structurally valid."
