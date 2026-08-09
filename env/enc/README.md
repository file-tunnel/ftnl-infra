# Encrypted environment bundles

Only `*.env.enc` SOPS ciphertext belongs here. Create or edit a production
bundle with `nix develop --command just edit prod`; never redirect decrypted
output into this directory and never commit `env/dec`.

The production bundle is intentionally not populated from ticket or chat text:
enter freshly rotated provider credentials through the SOPS editor so plaintext
does not get copied into shell history, command telemetry, or patch logs.
