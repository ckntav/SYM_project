# SYM project

Password-protected multi-report site deployed on GitHub Pages via [StatiCrypt](https://github.com/robinmoisson/staticrypt).

**Live page:** https://ckntav.github.io/SYM_project

---

## Deploy / add a report

```bash
chmod +x deploy.sh    # first time only

./deploy.sh  /path/to/report.html
```

The script will:
1. Prompt for a password (not stored anywhere)
2. Encrypt the landing page → `index.html`
3. Encrypt the report → `reports/<slug>/index.html`
4. Commit and push both

---

## Add a new report to the landing page

1. Edit `_src/index.html` — copy one of the `<a class="card">` blocks and update the text and `href`
2. Run `./deploy.sh <new-slug> /path/to/new_report.html`

---

## Password & remember-me

All pages are encrypted with the same password and shared salt (`.staticrypt-salt`).
Entering the password once on any page remembers it for **7 days** across the whole site.

---

## Salt — how it works

The `.staticrypt-salt` file contains a **random 32-character hex string** (128-bit) generated once and committed to the repo.

- It is shared across **all pages of this site** so the "Remember me" cookie works everywhere after a single login
- It is **not secret** — its only role is to make password hashes unique to this site
- **Never delete or regenerate it** unless you intend to invalidate all existing user sessions

### Generate a new salt (first-time or reset)

```bash
node -e "console.log(require('crypto').randomBytes(16).toString('hex'))" > .staticrypt-salt
```

> ⚠️ Regenerating the salt will force **all users to re-enter the password**, even if they had "Remember me" active.

### Deploying a second / separate website

Each independent site should have its **own** `.staticrypt-salt` file. Never share a salt across different sites.

```bash
# In the new repo:
node -e "console.log(require('crypto').randomBytes(16).toString('hex'))" > .staticrypt-salt
```

Then copy and adapt `deploy.sh` (update the GitHub Pages URL and any branding in the `--template-*` flags).

---

## First-time GitHub Pages setup (one-off)

1. Go to **Settings → Pages** in this repository
2. Set **Source** → Branch: `main`, folder: `/ (root)` → Save