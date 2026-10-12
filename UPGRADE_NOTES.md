# SimpleHost Cloud v2.0 — Upgrade Notes

This is a functional redesign of the launcher and key paths, not just a name substitution.

## Changed
- New SimpleHost Cloud interface with real host metrics, updated navigation, and dedicated Incus/non-KVM manager.
- New module loader downloads to a temporary file, requires HTTPS, fails on HTTP errors, and runs `bash -n` before executing.
- All internal launcher links are routed through `run.simplehost.qzz.io`; legacy source-owner URLs and previous project identity are removed from text source.
- Panel menu only advertises modules that are packaged and not explicitly disabled.
- SSL helper no longer deletes existing Certbot certificate/archive paths.
- Removed fake `.netrc` credential-writing logic from the former entrypoint.
- Generated 24-byte-hex DB passwords replaced known trivial passwords. Hardcoded third-party SMTP credentials removed; mail defaults to Laravel's `log` driver.
- Removed a default `admin` password flow in active Pterodactyl/Paymenter/Reviactyl installer prompts.
- Wings uninstall now preserves container data by default and never prunes Docker. Database setup no longer grants global privileges from `%` or opens port 3306 to everyone by default.
- Convoy installer no longer purges Apache or deletes `/var/www/html`; it stops when an active Apache conflict is detected. Data-destructive uninstalls and Docker-wide operations require typed confirmations.
- Disabled the supplied Jexactyl prototype, Hyper V1 add-on and a WHMCS-related module with unverified provenance.
- Legacy LVM/HVM module is guarded because it downloads an unverified binary.

## Still needs review before production use
- This archive contains many inherited installers and bundled third-party Blueprint assets. Not every line of every inherited installer has been independently audited or tested on a production server.
- A Bash syntax check is not a cryptographic signature or security audit. Hosting scripts on your domain means clients trust that domain's content and your deployment pipeline.
- Several downstream scripts still make OS/service/NGINX/database changes. Run first on a disposable VPS, inspect the module, and take backups.
- `ptero.simplehost.qzz.io` is only a suggested domain. DNS and TLS must be configured separately.
