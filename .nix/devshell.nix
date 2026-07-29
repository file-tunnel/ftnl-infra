{ pkgs, agentCheck }:
pkgs.mkShell {
  packages = [
    agentCheck
  ]
  ++ (with pkgs; [
    actionlint
    git
    jq
    kubeconform
    kubectl
    kustomize
    nixfmt
    ripgrep
    shellcheck
    shfmt
    yq-go
  ]);

  LANG = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";
  LC_ALL = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";

  shellHook = ''
    export FTNL_DEV_SHELL="infra"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$PWD/.cache/nix-agent}"
  '';
}
