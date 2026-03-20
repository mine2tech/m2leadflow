# M2Leadflow API — Curl Examples for LLM Agent

All requests require `X-Api-Key` header.
Base URL: `http://localhost:3001/api`
API Key (dev): `m2leadflow-dev-api-key-change-in-production`

```bash
export API_KEY="m2leadflow-dev-api-key-change-in-production"
export BASE="http://localhost:3001/api"
```

---

## Authentication

All API endpoints require the `X-Api-Key` header. Wrong key returns 401.

```bash
# ✅ Correct
curl -H "X-Api-Key: $API_KEY" $BASE/tasks/next

# ❌ Wrong key → {"error":"Unauthorized"} HTTP 401
curl -H "X-Api-Key: wrong-key" $BASE/tasks/next
```

---

## Task Lifecycle

The agent processes one task at a time: **next → claim → start → complete/fail**.

### 1. GET /api/tasks/next — Fetch the next pending task

Returns the oldest pending task. Returns `204 No Content` when queue is empty.

```bash
curl -s -H "X-Api-Key: $API_KEY" $BASE/tasks/next
```

**Response (200 — task available):**
```json
{
  "id": 5,
  "task_type": "draft_email",
  "payload": {
    "contact": { "name": "John Collison", "role": "President" },
    "contact_id": 3,
    "company_context": {
      "name": "Stripe",
      "notes": "Payments infrastructure company, Series H+, public.",
      "domain": "stripe.com"
    },
    "is_followup": false,
    "sequence_number": null
  },
  "status": "pending",
  "attempts": 0,
  "max_attempts": 3,
  "result": {},
  "error": null,
  "created_at": "2026-03-18T09:39:15.193Z",
  "updated_at": "2026-03-18T09:39:15.193Z"
}
```

**Response (204 — nothing to do):** empty body

---

### 2. POST /api/tasks/:id/claim — Claim a task

Transitions status: `pending → claimed`. Call immediately after fetching.

```bash
curl -s -X POST -H "X-Api-Key: $API_KEY" $BASE/tasks/5/claim
```

**Response (200):**
```json
{
  "id": 5,
  "status": "claimed",
  ...
}
```

---

### 3. POST /api/tasks/:id/start — Start a task

Transitions status: `claimed → in_progress`. Call before doing the work.

```bash
curl -s -X POST -H "X-Api-Key: $API_KEY" $BASE/tasks/5/start
```

**Response (200):**
```json
{
  "id": 5,
  "status": "in_progress",
  ...
}
```

---

### 4a. POST /api/tasks/:id/complete — Complete a task (draft_email)

Transitions status: `in_progress → completed`. The `result` object varies by task type.

**For `draft_email` tasks:**

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "result": {
      "subject": "Quick question about Stripe checkout flows",
      "body": "Hi John,\n\nSaw the recent Stripe Sessions keynote — really impressive what the team shipped on embedded components.\n\nWe'\''ve been building on top of Stripe and ran into some friction in the multi-party payout flows that I suspect other founders face too. Curious if that'\''s on your radar.\n\nWould you be open to a 15-min chat this week?\n\nBest,\nAvinash"
    }
  }' \
  $BASE/tasks/5/complete
```

**Response (200):**
```json
{
  "id": 5,
  "status": "completed",
  "result": {
    "subject": "Quick question about Stripe checkout flows",
    "body": "Hi John,\n\n..."
  },
  ...
}
```

The system automatically creates a `Draft` record linked to the contact. The draft appears in the contact's conversation thread in the UI.

---

**For `enrich_company` tasks:**

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "result": {
      "contacts": [
        {
          "name": "Patrick Collison",
          "email": "patrick@stripe.com",
          "role": "CEO",
          "source": "apollo",
          "confidence_score": 0.97
        },
        {
          "name": "John Collison",
          "email": "john@stripe.com",
          "role": "President",
          "source": "apollo",
          "confidence_score": 0.95
        }
      ]
    }
  }' \
  $BASE/tasks/3/complete
```

The system automatically saves contacts (deduplicates by email) and creates `draft_email` tasks for each new contact.

---

### 4b. POST /api/tasks/:id/fail — Fail a task

Call if execution fails. The task auto-retries up to `max_attempts` (default 3). After 3 failures it stays `failed`.

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"error": "Apollo account not available; web research insufficient to find verified contact email."}' \
  $BASE/tasks/6/fail
```

**Response (200):** Task with incremented `attempts`, status back to `pending` (if attempts < max) or `failed`.

```json
{
  "id": 6,
  "status": "pending",
  "attempts": 1,
  "error": "Apollo account not available; web research insufficient to find verified contact email.",
  ...
}
```

---

## Companies

### POST /api/companies — Create a company

Creates a company and auto-queues an `enrich_company` task.

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "company": {
      "name": "Acme Corp",
      "domain": "acme.com",
      "notes": "SaaS company, recently breached"
    }
  }' \
  $BASE/companies
```

**Response (201):**
```json
{
  "id": 13,
  "name": "Acme Corp",
  "domain": "acme.com",
  "status": "new_company",
  "notes": "SaaS company, recently breached"
}
```

### POST /api/companies/bulk — Bulk create companies

Creates multiple companies. Deduplicates by domain. Each creates an `enrich_company` task.

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "companies": [
      { "name": "Acme Corp", "domain": "acme.com", "notes": "SaaS" },
      { "name": "Globex", "domain": "globex.com", "notes": "Manufacturing" }
    ]
  }' \
  $BASE/companies/bulk
```

**Response (200):**
```json
{
  "created": 2,
  "skipped": [],
  "companies": [
    { "id": 13, "name": "Acme Corp", "domain": "acme.com" },
    { "id": 14, "name": "Globex", "domain": "globex.com" }
  ]
}
```

---

## Contacts

### POST /api/contacts/bulk — Bulk create contacts

Used after enriching a company. Deduplicates by email. **`company_id` must be inside each contact object.**

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contacts": [
      {
        "name": "Dave Hahn",
        "email": "dave.hahn@stripe.com",
        "role": "VP Engineering",
        "source": "linkedin",
        "confidence_score": 0.88,
        "company_id": 2
      },
      {
        "name": "Will Gaybrick",
        "email": "will@stripe.com",
        "role": "CFO",
        "source": "apollo",
        "confidence_score": 0.95,
        "company_id": 2
      }
    ]
  }' \
  $BASE/contacts/bulk
```

**Response (200):**
```json
{
  "created": 1,
  "skipped": [
    { "email": "will@stripe.com", "reason": "already exists" }
  ],
  "created_contacts": [
    { "id": 5, "email": "dave.hahn@stripe.com" }
  ]
}
```

**Common skip reasons:**
- `"already exists"` — email already in DB (idempotent, safe to re-run)
- `errors: ["Company must exist"]` — `company_id` missing or wrong

---

## Drafts

### POST /api/drafts/bulk — Bulk create drafts

Alternative to the task system for directly inserting draft content. Useful for batch seeding or testing.

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "drafts": [
      {
        "contact_id": 4,
        "subject": "Quick question about Stripe treasury",
        "body": "Hi Will,\n\nFollowing up on the treasury products side — curious if the multi-ledger complexity is something your team is solving internally.\n\nHappy to share what we built.\n\nAvinash"
      }
    ]
  }' \
  $BASE/drafts/bulk
```

**Response (200):**
```json
{
  "created": 1,
  "drafts": [
    { "id": 4, "contact_id": 4 }
  ]
}
```

---

## Apollo Accounts

### GET /api/apollo/available — Check for an active Apollo account

Returns account credentials if one is available with remaining credits.

```bash
curl -s -H "X-Api-Key: $API_KEY" $BASE/apollo/available
```

**Response (200 — account available):**
```json
{
  "id": 1,
  "email": "you@company.com",
  "credits_remaining": 95,
  "credentials": "..."
}
```

**Response (404 — no accounts):**
```json
{ "error": "No active Apollo accounts" }
```

Always call this before attempting Apollo enrichment. If 404, fall back to web research.

---

### POST /api/apollo/usage — Update credits after use

Call after Apollo API calls to track remaining credits. Pass the Apollo account `id` (from the `/available` response) and updated `credits_remaining`.

```bash
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "credits_remaining": 90}' \
  $BASE/apollo/usage
```

**Response (200):**
```json
{ "status": "updated" }
```

If `credits_remaining` reaches 0, the account is automatically marked `exhausted` and excluded from future `/available` responses.

---

## Full Agent Loop Example

```bash
#!/bin/bash
export API_KEY="m2leadflow-dev-api-key-change-in-production"
export BASE="http://localhost:3001/api"

# 1. Fetch next task
RESPONSE=$(curl -s -w "\n%{http_code}" -H "X-Api-Key: $API_KEY" $BASE/tasks/next)
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" = "204" ]; then
  echo "No pending tasks."
  exit 0
fi

TASK_ID=$(echo $BODY | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
TASK_TYPE=$(echo $BODY | python3 -c "import sys,json; print(json.load(sys.stdin)['task_type'])")

echo "Processing task $TASK_ID ($TASK_TYPE)"

# 2. Claim
curl -s -X POST -H "X-Api-Key: $API_KEY" $BASE/tasks/$TASK_ID/claim > /dev/null

# 3. Start
curl -s -X POST -H "X-Api-Key: $API_KEY" $BASE/tasks/$TASK_ID/start > /dev/null

# 4. ... do the work ...

# 5a. Complete (draft_email example)
curl -s -X POST \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"result":{"subject":"...","body":"..."}}' \
  $BASE/tasks/$TASK_ID/complete

# 5b. Or fail
# curl -s -X POST \
#   -H "X-Api-Key: $API_KEY" \
#   -H "Content-Type: application/json" \
#   -d '{"error":"reason for failure"}' \
#   $BASE/tasks/$TASK_ID/fail
```

---

## Error Reference

| HTTP | Meaning | Common Cause |
|------|---------|--------------|
| 200 | Success | — |
| 204 | No content | Queue empty (`GET /tasks/next`) |
| 400 | Bad request | Malformed JSON, missing required field |
| 401 | Unauthorized | Wrong or missing `X-Api-Key` header |
| 404 | Not found | Record doesn't exist (apollo/available with no accounts) |
| 500 | Server error | Bug / unexpected state — check Rails logs |

---

## Test Results (verified 2026-03-20)

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/api/tasks/next` | GET | ✅ 200/204 | Returns task JSON or empty |
| `/api/tasks/:id/claim` | POST | ✅ 200 | |
| `/api/tasks/:id/start` | POST | ✅ 200 | |
| `/api/tasks/:id/complete` | POST | ✅ 200 | Creates Draft or Contacts automatically |
| `/api/tasks/:id/fail` | POST | ✅ 200 | Auto-retries up to max_attempts |
| `/api/companies` | POST | ✅ 201 | Auto-creates enrich_company task |
| `/api/companies/bulk` | POST | ✅ 200 | Deduplicates by domain |
| `/api/contacts/bulk` | POST | ✅ 200 | company_id must be inside each contact |
| `/api/drafts/bulk` | POST | ✅ 200 | |
| `/api/apollo/available` | GET | ✅ 200 | Returns account with credits |
| `/api/apollo/usage` | POST | ✅ 200 | Updates credit balance |
| Auth (bad key) | — | ✅ 401 | |
