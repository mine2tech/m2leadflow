# M2Leadflow

Cold email outbound system for founders. Rails 8.1.2 monolith.

## Tech Stack
- Ruby 3.4.9 (rbenv), Rails 8.1.2, PostgreSQL 16.13
- Turbo/Hotwire + Tailwind CSS v4.2.1 (ERB views, no SPA)
- Solid Queue for background jobs (recurring jobs only run in production)
- Google Gmail API (`google-apis-gmail_v1` gem) for sending + reply tracking
- Google Calendar API for meeting sync
- Active Storage for draft attachments
- Devise for user auth (roles: editor, admin)

## Architecture
Task-driven. The app creates tasks → external Claude agent (`/cowork` skill) pulls and executes them → results flow back via API.

```
User creates Company → enrich_company task created
Claude enriches → contacts saved → draft_email tasks created
Claude drafts emails → Drafts appear in UI
User reviews → approves → sends via Gmail API
Gmail polling detects replies → stored as inbound messages → classify_reply task created
Claude classifies reply (interested/not_interested/out_of_office/wrong_person/auto_reply)
  → interested: AI-suggested reply draft created
  → not_interested: pending followups auto-skipped
  → out_of_office: followups snoozed
Followup job checks for unreplied contacts → creates new draft tasks
```

## Key Directories
- `app/models/` — Company, Contact, EmailThread, Message, Draft, Followup, Meeting, ApolloAccount, Task, GmailAccount, CalendarAccount, Setting, User, Activity, Comment
- `app/controllers/api/` — JSON API for Claude agent (task lifecycle + data endpoints)
- `app/controllers/` — UI controllers (Devise auth)
- `app/services/` — GmailSendingService, GmailPollingService, EmailSendingService, FollowupService, CalendarService, ActivityTracker, SlackNotificationService, TaskResultProcessors/
- `app/jobs/` — GmailPollJob (3min), FollowupCheckJob (hourly), ScheduledEmailSendJob (5min), ReplyReminderJob (hourly), DailyDigestJob (9am)
- `.claude/skills/cowork.md` — The Claude agent skill that processes tasks

## Running
```bash
bin/rails server -p 3001   # Web server (port 3000 used by mine2portal)
bin/jobs                    # Background job worker (only needed for production-like testing)
```

Local testing: `http://localhost:3001`. Remote/production: `144.24.119.241:3000` (Docker).
Recurring jobs (`config/recurring.yml`) only run in production. To test locally, call services directly:
```bash
bin/rails runner "GmailPollingService.call"       # Poll for replies
bin/rails runner "FollowupService.check_and_create" # Create followups
bin/rails runner "DailyDigestJob.perform_now"     # Test digest
```

## Deploy
```bash
# From local machine:
cd ~/projects/mine2
tar czf /tmp/m2leadflow.tar.gz \
  --exclude='.git' --exclude='node_modules' --exclude='log/*' \
  --exclude='tmp/*' --exclude='storage/*' --exclude='.bundle' \
  --exclude='.env' --exclude='.env.production' --exclude='config/master.key' \
  --exclude='.claude/skills/cowork_config.json' --exclude='*.png' \
  m2leadflow/

scp -i ~/keys/m2/m2portal.pem /tmp/m2leadflow.tar.gz root@144.24.119.241:/tmp/

ssh -i ~/keys/m2/m2portal.pem root@144.24.119.241
cd /opt/m2leadflow
cp .env.production /tmp/.env.production.bak
tar xzf /tmp/m2leadflow.tar.gz --strip-components=1 --overwrite
cp /tmp/.env.production.bak .env.production
docker compose build --no-cache
docker compose down && docker compose up -d
# If migration needed: docker exec m2leadflow-web-1 bundle exec rails db:migrate
```
See `DEPLOY.md` for full setup, DB restore, and gotchas.

## Auth
- UI: Devise (email/password), roles: editor (can send), admin (can send + manage settings/users)
- API: X-Api-Key header (API_KEY from .env)

## Git Commits
- Keep commit messages short (one line, no body unless necessary)
- Do NOT include co-authored-by or Claude branding

## Important Gotchas

### Thread → EmailThread
Ruby reserves `Thread`. The model is `EmailThread` with table `email_threads`.

### Gmail API: Use upload_source, NOT raw
The Gmail send API requires `upload_source: StringIO.new(message.to_s)` with `content_type: "message/rfc822"`. Do NOT use `raw: Base64.urlsafe_encode64(...)` — it silently drops recipient headers and fails with "Recipient address required".

### MIME attachments: multipart/mixed, NOT multipart/alternative
When building emails with attachments using the Mail gem, do NOT use `mail.text_part=` + `mail.html_part=` + `mail.add_file` together. This creates a flat `multipart/alternative` where the attachment is treated as an alternative to the text body — email clients won't show it as an attachment.

Instead, manually build the structure:
```ruby
alt_part = Mail::Part.new(content_type: "multipart/alternative")
alt_part.add_part(text_part)
alt_part.add_part(html_part)
mail.add_part(alt_part)
mail.add_file(filename: ..., content: ...)
# Result: multipart/mixed > [multipart/alternative > [text, html], attachment]
```

### Gmail polling: body data is already decoded
The Google API gem (`google-apis-gmail_v1`) returns message body data as already-decoded UTF-8 text, NOT base64. Do not base64-decode it — check `valid_encoding?` first and use as-is if it's valid UTF-8.

### Gmail polling: match replies by thread_id
Match inbound replies using `EmailThread.find_by(external_thread_id: msg.thread_id)`. Do NOT try to match by `In-Reply-To`/`References` headers against stored `gmail_message_id` — they use different ID formats (RFC 2822 Message-ID vs Gmail API ID).

### Contacts can be phone-only
The Contact model allows `email: nil` if `phone` is present. Always check `contact.email.present?` before showing send buttons or attempting to send. The GmailSendingService validates this, but UI should hide send options for phone-only contacts.

### Turbo Stream actions need stable dom_ids
Draft cards use `turbo_frame_tag dom_id(draft)` and rows use `div id="dom_id(draft, :row)"`. The controller sends `turbo_stream.replace` targeting both. Ensure partials always wrap in the matching ID.

### Status transitions need guards
Always check current status before transitioning. The `approve`, `send_email`, and `send_later` actions all have idempotency guards. Without them, double-clicks or stale pages cause duplicate activities, duplicate emails, or invalid state transitions.

### Button disable on submit
Use `data: { turbo_submits_with: "Loading..." }` on all `button_to` actions that trigger server-side work (Review, Send, Schedule). Prevents double-clicks during network latency.

## Testing Practices

### Always verify from the recipient's perspective
A successful API call does NOT mean the email is correct. After sending:
1. Fetch the sent message via Gmail API and inspect MIME structure
2. Verify attachments appear as separate `application/*` parts under `multipart/mixed`
3. Check the recipient's inbox — does the email render correctly?

### Test the full flow, not just individual steps
Don't just test "draft created" or "API returned 200". Test the entire chain:
- Create draft with attachment → review → send → verify in recipient inbox → reply → verify polling picks it up → verify followup logic

### Test with real data
Use real PDFs, real email addresses (atechnodrifter@gmail.com for testing), real Gmail OAuth tokens. Dummy data like `'x' * 5_000_000` won't catch MIME encoding issues.

## Task Types
- `enrich_company` — Find contacts via Apollo/web research
- `draft_email` — Write cold email or followup (has `is_followup` and `sequence_number` in payload)
- `company_research` — Find companies matching criteria
- `classify_reply` — Classify inbound reply and suggest response
