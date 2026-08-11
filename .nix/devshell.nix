{ pkgs, agentCheck }:
pkgs.mkShell {
  packages = [
    agentCheck
  ]
  ++ (with pkgs; [
    actionlint
    age
    git
    just
    jq
    kubeconform
    kubectl
    kustomize
    nixfmt
    pkgs.ores-sops
    python3
    ripgrep
    shellcheck
    shfmt
    sops
    supabase-cli
    yq-go
  ]);

  LANG = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";
  LC_ALL = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";

  shellHook = ''
    # `env/dec/` is local plaintext and intentionally absent from Git. Prepare
    # its owner-only boundary before SOPS, Just, hooks, or provider tooling run.
    _repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    if [ -L "$_repo_root/env" ] || [ -L "$_repo_root/env/dec" ]; then
      echo "refusing to prepare symlinked env/dec" >&2
      return 1 2>/dev/null || exit 1
    fi
    umask 077
    mkdir -p "$_repo_root/env/dec"
    chmod 700 "$_repo_root/env/dec"
    unset _repo_root

    export FTNL_DEV_SHELL="infra"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$PWD/.cache/nix-agent}"
  '';
}
