# Encrypted environment bundles

Only `env/enc/dev.env.enc` and `env/enc/prod.env.enc` SOPS ciphertext belong
under `env/enc`. Create or edit a production bundle with
`nix develop --command just edit prod`; never redirect decrypted output into
that directory and never commit `env/dec`.

Enter freshly rotated provider credentials through the SOPS editor so
plaintext does not get copied into shell history, command telemetry, or patch
logs. Revoke the superseded provider credential only after the replacement
ciphertext is verified and pushed.
