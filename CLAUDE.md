# M2Leadflow

Cold email outbound system for founders. Rails 8.1.2 monolith.

## Tech Stack
- Ruby 3.4.9 (rbenv), Rails 8.1.2, PostgreSQL 16.13
- Turbo/Hotwire + Tailwind CSS (ERB views, no SPA)
- Solid Queue for background jobs
- Google Gmail API for reply tracking

## Architecture
Task-driven. The app creates tasks → external Claude agent (`/cowork` skill) pulls and executes them → results flow back via API.

```
User creates Company → enrich_company task created
Claude enriches → contacts saved → draft_email tasks created
Claude drafts emails → Drafts appear in UI
User reviews → approves → sends
Gmail polling detects replies → stored as inbound messages
Followup job checks for unreplied contacts → creates new draft tasks
```

## Key Directories
- `app/models/` — 11 models (Company, Contact, EmailThread, Message, Draft, Followup, Meeting, ApolloAccount, Task, GmailAccount, Setting)
- `app/controllers/api/` — JSON API for Claude agent (task lifecycle + data endpoints)
- `app/controllers/` — UI controllers (Basic Auth protected)
- `app/services/` — EmailSendingService, GmailPollingService, FollowupService, TaskResultProcessors
- `app/jobs/` — GmailPollJob (every 3min), FollowupCheckJob (hourly)
- `.claude/skills/cowork.md` — The Claude agent skill that processes tasks

## Running
```bash
bin/rails server -p 3001   # Web server (port 3000 used by mine2portal)
bin/jobs                    # Background job worker
```

## API Auth
- UI: HTTP Basic Auth (BASIC_AUTH_USERNAME/PASSWORD from .env)
- API: X-Api-Key header (API_KEY from .env)

## Important: Thread → EmailThread
Ruby reserves `Thread`. The model is `EmailThread` with table `email_threads`.
