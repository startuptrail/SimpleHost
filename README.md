# SimpleHost Cloud

**A modular Linux VPS / Pterodactyl toolkit.** This distribution includes panel installers, Wings management, VM helpers, network tools, Blueprint theme/extension helpers, and infrastructure modules.

## Branded endpoints

- Installer/script host: `https://run.simplehost.qzz.io`
- Suggested Pterodactyl Panel hostname: `https://ptero.simplehost.qzz.io`

These are configuration examples, not a claim that DNS, TLS, or a panel has already been configured. Point `ptero.simplehost.qzz.io` to the server that will actually run the Panel. Point `run.simplehost.qzz.io` at a static host serving this repository's files.

## Quick start after hosting

```bash
curl -fsSL https://run.simplehost.qzz.io/install.sh -o /tmp/simplehost-install.sh
bash -n /tmp/simplehost-install.sh
less /tmp/simplehost-install.sh
sudo bash /tmp/simplehost-install.sh
```

For a local checkout, run `bash install.sh`. The top-level menu can load local modules, but several nested menus still use `run.simplehost.qzz.io`; configure and deploy the static script host before expecting every nested option to work. Remotely loaded modules are downloaded to a temporary file and syntax-checked before execution.

## Host the bundle at `run.simplehost.qzz.io`

1. Upload the contents of this repository to your own GitHub repository.
2. Create a Cloudflare Pages project connected to that repository, with the repository root as the output directory and no build command.
3. Keep `_worker.js` in the published root; it maps `/` to `/install.sh` and serves remaining files as static assets.
4. Add `run.simplehost.qzz.io` as the Pages custom domain and confirm TLS is active.
5. Test `https://run.simplehost.qzz.io/install.sh` and `https://run.simplehost.qzz.io/panel/1.sh` in a browser before running the one-liner.
6. Configure `ptero.simplehost.qzz.io` separately to point to the Panel server; it is not the script host.

## Improvements in this edition

- Rebuilt the main terminal UI with actual OS, CPU, RAM, disk, uptime and local-IP metrics.
- Added a real system diagnostic module instead of a dead link to a separate repository.
- Replaced the original `.netrc` fake-credential sequence; no bogus username/password are written to the user's home directory.
- Reworked panel selection to show only modules bundled in this repository.
- Added a temporary-file download helper with HTTPS-only curl settings and a Bash syntax check before module execution.
- Replaced the broken SSL helper that removed existing Certbot files with a non-destructive Certbot flow.
- Removed hardcoded database passwords and embedded SMTP credentials from text installer scripts; generated DB passwords are used, and mail defaults to Laravel's `log` driver until you configure your own SMTP.
- Added strict domain/identifier validation in active install flows, stronger confirmations for data removal and Docker-wide actions, and a database access module that limits grants to one database and a specified source IP.
- Updated Pterodactyl/Reviactyl update flows to back up `.env`/storage and overlay release files rather than wiping the live web root first. A broken Reviactyl migration routine and unaudited external Hyper V1 module are disabled.
- Removed references to upstream author's personal raw-GitHub paths from the interactive launchers.

## Requirements and warnings

- Most installers require Ubuntu/Debian and root privileges. Individual modules have different compatibility requirements.
- Back up your server before installing or removing services. Panel, database, Docker, VM, and storage operations can cause downtime or data loss.
- The loader's syntax check does **not** prove a script is trustworthy; Bash syntax validation is not a security review. You are still trusting the contents served from your script host.
- Legacy modules inherited from the supplied archive have not all been audited. `Extras/lvm.sh`, WHMCS-related install paths, the Jexactyl prototype and the Hyper V1 add-on are disabled or guarded; review panel-specific third-party code before enabling any legacy path.
- Third-party Blueprint archives are preserved as supplied; their own internal branding/licensing/maintainer metadata is not rewritten.

## Suggested panel defaults

The Panel installer suggests `ptero.simplehost.qzz.io` as a domain, but you can enter another host. DNS must already point to the correct server and ports 80/443 must be reachable for standard HTTP-01 certificate validation.
