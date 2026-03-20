# M2Leadflow

Cold email outbound system for Mine2. Finds security decision-makers at target companies, drafts personalized cold emails, and manages the full outreach pipeline from prospect to meeting.

## How it works

```
Add Company  -->  AI enriches (finds CISOs via Apollo)  -->  AI drafts cold email
    |                                                              |
    v                                                              v
enrich_company task                                    Draft appears in UI
    |                                                              |
    v                                                              v
Contacts saved                                    You review --> Approve --> Send
    |                                                              |
    v                                                              v
draft_email tasks auto-created              Gmail polls for replies --> Followups auto-created
```

**The key idea**: You add companies. An external AI agent (Claude) does the research and writing. You just review and hit send.

## Quick start

### Prerequisites

- Ruby 3.4.x (via rbenv)
- PostgreSQL 16+
- Node.js (for Tailwind CSS build)

### Setup

```bash
git clone <repo> && cd m2leadflow
cp .env.example .env        # Edit with your credentials
bundle install
bin/rails db:create db:migrate
bin/rails tailwindcss:build  # Compile Tailwind CSS
```

### Run

```bash
bin/rails server -p 3001     # Web UI + API (port 3001, 3000 is used by mine2portal)
bin/jobs                     # Background jobs (Gmail polling, followup checks)
```

Open http://localhost:3001 — login with BASIC_AUTH_USERNAME/PASSWORD from .env.

### Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `BASIC_AUTH_USERNAME` | Yes | UI login username |
| `BASIC_AUTH_PASSWORD` | Yes | UI login password |
| `API_KEY` | Yes | API authentication key for Claude agent |
| `GMAIL_CLIENT_ID` | For email | Google OAuth client ID |
| `GMAIL_CLIENT_SECRET` | For email | Google OAuth client secret |
| `GMAIL_REDIRECT_URI` | For email | OAuth redirect (http://localhost:3001/auth/gmail/callback) |
| `HUNTER_API_KEY` | Optional | Hunter.io email verification (100 free/month) |

## For users

### Adding companies

1. Click **Add Company** on the dashboard
2. Enter: Name, Domain, Notes (breach context, industry, etc.)
3. An enrichment task is auto-created for the AI agent

Or via API:
```bash
curl -X POST -H "X-Api-Key: YOUR_KEY" -H "Content-Type: application/json" \
  -d '{"company":{"name":"Acme Corp","domain":"acme.com","notes":"Recently breached"}}' \
  http://localhost:3001/api/companies
```

### Pipeline stages

Each contact progresses through:

| Stage | Meaning |
|-------|---------|
| **Pending** | Contact found, no draft yet |
| **Drafted** | AI wrote a cold email, awaiting your review |
| **Sent** | Email sent via Gmail |
| **Replied** | Prospect replied (detected by Gmail polling) |
| **Meeting** | Meeting scheduled |

### Reviewing drafts

1. Go to a Company page, click a contact name
2. See the split-pane view: actions on the left, conversation timeline on the right
3. Review the AI-drafted email
4. **Edit** if needed, then **Approve**, then **Send**

### Followups

After a configurable delay (default 3 days), the system checks for unreplied contacts and either:
- Creates an AI-drafted followup (if followup_use_ai is enabled)
- Creates a template followup

Configure via Settings page: delay days, max followups, auto-send toggle.

## For developers

### Architecture

Rails 8.1.2 monolith with:
- **Turbo/Hotwire** for SPA-like interactions without JavaScript
- **Tailwind CSS v4** via tailwindcss-rails gem
- **Solid Queue** for background jobs
- **PostgreSQL** with jsonb for flexible task payloads

### Models (11)

```
Company (1) ---> (N) Contact (1) ---> (N) EmailThread (1) ---> (N) Message
                      |                     |
                      +---> (N) Draft ------+  (optional thread link)
                      +---> (N) Followup ---> (1) Draft
                      +---> (N) Meeting

Task              (standalone, jsonb payload/result)
ApolloAccount     (credit tracking)
GmailAccount      (OAuth tokens, encrypted)
Setting           (key-value config)
```

### Task system

The core pattern: tasks are created by the app, processed by an external Claude agent via API.

```
Task lifecycle:  pending --> claimed --> in_progress --> completed
                                                    --> failed (auto-retries up to 3x)
```

**Task types:**
- `enrich_company` — Find security contacts at a company (via Apollo.io browser automation)
- `draft_email` — Write a personalized cold email for a contact

### API endpoints

All require `X-Api-Key` header. Full examples in `docs/api_curl_examples.md`.

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/tasks/next` | GET | Fetch next pending task |
| `/api/tasks/:id/claim` | POST | Claim a task |
| `/api/tasks/:id/start` | POST | Start processing |
| `/api/tasks/:id/complete` | POST | Submit results |
| `/api/tasks/:id/fail` | POST | Report failure |
| `/api/companies` | POST | Create company (auto-queues enrichment) |
| `/api/companies/bulk` | POST | Bulk create companies |
| `/api/contacts/bulk` | POST | Bulk create contacts |
| `/api/drafts/bulk` | POST | Bulk create drafts |
| `/api/apollo/available` | GET | Check Apollo account credits |
| `/api/apollo/usage` | POST | Update credit balance |

### Key directories

```
app/models/                          # 11 models
app/controllers/                     # UI controllers (Basic Auth)
app/controllers/api/                 # JSON API for Claude agent
app/services/                        # Business logic
  email_sending_service.rb           # Send via Gmail API
  gmail_polling_service.rb           # Poll for replies
  followup_service.rb                # Auto-create followups
  task_result_processors/            # Process completed tasks
    enrich_company.rb                # Save contacts, mark enriched
    draft_email.rb                   # Create Draft record
app/jobs/                            # Background jobs
  gmail_poll_job.rb                  # Every 3 minutes
  followup_check_job.rb             # Every hour
app/views/                           # ERB + Turbo Frames
.claude/skills/cowork.md             # Claude agent skill definition
docs/api_curl_examples.md            # Full API documentation with curl examples
```

### The Claude agent (cowork skill)

The file `.claude/skills/cowork.md` defines how Claude processes tasks:

**For `enrich_company`:**
1. Check Apollo credits via API
2. Open Apollo.io People search in browser
3. Filter by Company name + Job Title (CISO, VP Security)
4. Click "Access email" to reveal emails (1 credit each)
5. Optionally validate emails via Hunter.io
6. Submit contacts back via API

**For `draft_email`:**
1. Research the company and contact
2. Write a 3-5 sentence personalized cold email
3. Submit draft back via API

Invoke with: `/cowork` in Claude Code.

### Important notes

- **Thread model**: Ruby reserves `Thread`, so the model is `EmailThread` (table: `email_threads`)
- **Port 3001**: Port 3000 is used by the Mine2 portal app
- **Tailwind rebuild**: After changing views, run `bundle exec rails tailwindcss:build`
- **Gmail tokens**: Encrypted at rest via Rails 8 `encrypts` macro
- **API key**: Only accepted from `X-Api-Key` header (never query params)

### Running the full pipeline

```bash
# 1. Start server + jobs
bin/rails server -p 3001 &
bin/jobs &

# 2. Add a company (creates enrich_company task)
curl -X POST -H "X-Api-Key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"company":{"name":"Target Corp","domain":"target.com","notes":"Retail, recently breached"}}' \
  http://localhost:3001/api/companies

# 3. Run the cowork skill in Claude Code
# /cowork
# It will: fetch task -> search Apollo -> submit contacts -> fetch draft task -> write email -> submit

# 4. Review drafts in the UI at http://localhost:3001
# Approve -> Send -> Wait for replies -> Followups auto-created
```
