# M2Leadflow — Setup & Configuration Guide

## 1. Prerequisites

- Ruby 3.4.9 via rbenv (already installed at `~/.rbenv/`)
- PostgreSQL 16.13 (already running)
- Node.js (for Tailwind CSS compilation — check with `node --version`)

## 2. Start the App

```bash
cd /home/avinash/projects/mine2/m2leadflow
bin/rails server -p 3001
```

Open http://localhost:3001 — login with Basic Auth credentials from `.env`.

## 3. Credentials to Configure

### `.env` file — `/home/avinash/projects/mine2/m2leadflow/.env`

| Variable | What It Is | How to Get It | Required For |
|----------|-----------|---------------|-------------|
| `DATABASE_PASSWORD` | PostgreSQL password | Already set: `Secure123` | Database connection |
| `BASIC_AUTH_USERNAME` | UI login username | Set any value (default: `admin`) | Accessing the web UI |
| `BASIC_AUTH_PASSWORD` | UI login password | Set any value (default: `changeme`) | Accessing the web UI |
| `API_KEY` | API key for Claude agent | Generate: `openssl rand -hex 32` | Claude agent ↔ API communication |
| `SMTP_ADDRESS` | SMTP server | `smtp.gmail.com` for Google Workspace | Sending emails (production) |
| `SMTP_PORT` | SMTP port | `587` for Gmail | Sending emails (production) |
| `SMTP_DOMAIN` | Your email domain | e.g. `mine2.io` | Sending emails (production) |
| `SMTP_USERNAME` | Gmail address | Your Google Workspace email | Sending emails (production) |
| `SMTP_PASSWORD` | Gmail App Password | See "Gmail App Password" below | Sending emails (production) |
| `GMAIL_CLIENT_ID` | Google OAuth Client ID | See "Gmail OAuth Setup" below | Reply tracking |
| `GMAIL_CLIENT_SECRET` | Google OAuth Client Secret | See "Gmail OAuth Setup" below | Reply tracking |
| `GMAIL_REDIRECT_URI` | OAuth callback URL | `http://localhost:3001/auth/gmail/callback` | Reply tracking |

### What Works Without Configuration

- **Everything except email sending and reply tracking.** You can create companies, contacts, manage tasks, review drafts — all without configuring SMTP or Gmail OAuth.
- **Email sending in dev** uses `letter_opener` — emails open in the browser, no real SMTP needed.

---

## 4. Gmail App Password (for SMTP sending)

This is needed only when you want to actually send emails (production or testing with real email).

1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification (required)
3. Go to https://myaccount.google.com/apppasswords
4. Select "Mail" and your device
5. Google generates a 16-character password
6. Put it in `.env` as `SMTP_PASSWORD`

```
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=you@yourdomain.com
SMTP_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

---

## 5. Gmail OAuth Setup (for Reply Tracking)

This is needed to detect when prospects reply to your cold emails.

### Step 1: Create Google Cloud Project
1. Go to https://console.cloud.google.com/
2. Create a new project (e.g. "M2Leadflow")
3. Enable the **Gmail API**: APIs & Services → Library → search "Gmail API" → Enable

### Step 2: Configure OAuth Consent Screen
1. APIs & Services → OAuth consent screen
2. Choose "External" user type
3. Fill in app name: "M2Leadflow"
4. Add your email as a test user
5. Add scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`

### Step 3: Create OAuth Credentials
1. APIs & Services → Credentials → Create Credentials → OAuth client ID
2. Application type: "Web application"
3. Name: "M2Leadflow"
4. Authorized redirect URIs: `http://localhost:3001/auth/gmail/callback`
5. Copy the **Client ID** and **Client Secret**

### Step 4: Add to `.env`
```
GMAIL_CLIENT_ID=xxxxxxxxxxxx.apps.googleusercontent.com
GMAIL_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxx
GMAIL_REDIRECT_URI=http://localhost:3001/auth/gmail/callback
```

### Step 5: Connect in App
1. Go to http://localhost:3001/settings
2. Click "Connect Gmail Account"
3. Authorize with your Google account
4. The polling job will now check for replies every 3 minutes

---

## 6. Apollo Account (Optional)

Apollo accounts are used by the Claude agent for company enrichment (finding contacts). Add via Rails console:

```bash
bin/rails console
```

```ruby
ApolloAccount.create!(
  email: "your-apollo@email.com",
  credentials_encrypted: "your-apollo-api-key-or-cookie",
  credits_remaining: 1000,
  reset_date: Date.today + 30,
  status: :active
)
```

---

## 7. ActiveRecord Encryption Keys

Already configured in `config/initializers/active_record_encryption.rb` with development keys. For production, set these env vars:

```
AR_ENCRYPTION_PRIMARY_KEY=<generate with: openssl rand -hex 16>
AR_ENCRYPTION_DETERMINISTIC_KEY=<generate with: openssl rand -hex 16>
AR_ENCRYPTION_KEY_DERIVATION_SALT=<generate with: openssl rand -hex 16>
```

---

## 8. Background Jobs (Solid Queue)

Rails 8 ships with Solid Queue. To run background jobs (Gmail polling, followup checks):

```bash
bin/jobs
```

Or use `bin/dev` which starts both the web server and job worker via Procfile.

---

## 9. API Key for Claude Agent

The Claude agent (skill) needs this key to authenticate with the API. Generate a strong one:

```bash
openssl rand -hex 32
```

Put it in `.env` as `API_KEY`. The same key must be configured in the Claude skill.

---

## 10. Quick Checklist

| Step | Status |
|------|--------|
| App boots (`bin/rails server -p 3001`) | Test it |
| Can log into UI at http://localhost:3001 | Use admin/changeme |
| Can create a company | Creates enrichment task automatically |
| Can create a contact | Creates draft_email task automatically |
| Task Monitor shows tasks | http://localhost:3001/task_monitor |
| Configure API_KEY in `.env` | For Claude agent |
| Install `/cowork` Claude skill | See `COWORK_SKILL.md` |
| Run `/cowork` to process tasks | Claude does the work |
| (Optional) Configure SMTP | For real email sending |
| (Optional) Configure Gmail OAuth | For reply tracking |
| (Optional) Run `bin/jobs` | For automated followups + reply polling |
