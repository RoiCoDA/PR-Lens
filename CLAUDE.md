# PRLens

## What This Is
A full-stack web app that reviews GitHub Pull Requests using AI.
The user pastes a PR URL → the app fetches the diff via GitHub API →
sends it to Claude's API → returns structured review results with
severity levels, categories, and fix suggestions. Results are stored
in a database and displayed in a clean UI.

## Stack
- **Backend:** Node.js + TypeScript + Express
- **ORM:** Prisma
- **Database:** PostgreSQL
- **Frontend:** React + Vite + TailwindCSS + shadcn/ui
- **AI:** Anthropic Claude API (claude-sonnet-4-20250514)
- **GitHub integration:** Octokit (GitHub's official SDK)
- **Deployment:** Render (web service + static site + managed PostgreSQL)

## Project Structure
```
prlens/
├── CLAUDE.md
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── reviews.ts        # POST /reviews, GET /reviews/:id
│   │   │   └── github.ts         # proxy/helper routes
│   │   ├── services/
│   │   │   ├── github.ts         # fetch PR diff via Octokit
│   │   │   └── claude.ts         # call Anthropic API, parse JSON
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   └── index.ts
│   └── package.json
│
└── frontend/
    ├── src/
    │   ├── components/
    │   │   ├── SettingsPanel.tsx  # Anthropic + GitHub key inputs (BYOK)
    │   │   ├── ReviewForm.tsx     # PR URL input + submit
    │   │   ├── FlawList.tsx       # list of flaw cards
    │   │   └── FlawCard.tsx       # individual flaw display
    │   ├── pages/
    │   │   ├── Home.tsx
    │   │   └── Review.tsx
    │   └── main.tsx
    └── package.json
```

## Key Design Decisions

### No Authentication
There are no user accounts, login, sessions, or registration.
Anyone can use the app by providing their own API keys.
This was a deliberate scope decision — auth adds complexity with no impact
on the core value proposition (the AI review).

### BYOK — Bring Your Own Keys
Users provide two keys via a settings panel in the UI:
- **Anthropic API key** — used to call Claude for the review
- **GitHub token** (optional) — raises GitHub rate limit from 60 to 5,000 req/hour

Both keys are:
- Stored only in React state (sessionStorage at most) — never in the DB
- Sent from frontend to backend as request headers per call
- Never logged, never persisted
- The UI explicitly tells the user: "Your keys are used only for this request and never stored."

### PRs Only — No Full Repo Analysis
PRLens reviews diffs only — what changed in a PR, not the entire codebase.
- The base repo is ignored entirely
- A PR diff is the correct unit of review (it's what changed)
- This is how all serious tools work (CodeRabbit, GitHub Copilot, etc.)
- Full repo auditing is a different product — out of scope for v1

## Data Model
```
Review
  id           String   @id
  pr_url       String
  pr_title     String?
  repo         String
  created_at   DateTime
  flaws        Flaw[]

Flaw
  id           String   @id
  review_id    String
  file         String
  line         Int?
  severity     String   # "critical" | "major" | "minor" | "suggestion"
  category     String   # "security" | "performance" | "logic" | "style" | "maintainability"
  description  String
  suggestion   String
```

## Claude API — Core Prompt Shape
```
You are a senior software engineer performing a code review.
Analyze the following PR diff and return ONLY a JSON array of flaws.

Each flaw must have:
- file: string
- line: number | null
- severity: "critical" | "major" | "minor" | "suggestion"
- category: "security" | "performance" | "logic" | "style" | "maintainability"
- description: string (what is wrong)
- suggestion: string (how to fix it)

Return ONLY valid JSON. No explanation, no markdown, no code fences.

PR DIFF:
${diff}
```

## API Response Shape
All backend responses follow this structure:
```typescript
{ data: T | null, error: string | null }
```

## Request Headers (sent from frontend per call)
```
x-anthropic-key: <user's Anthropic API key>
x-github-token: <user's GitHub token>   ← optional
```
The backend reads these headers, uses them for the respective API calls, and discards them.
Never log these headers. Never store them.

## Build Order
Follow this sequence strictly — each step depends on the previous:
1. **Prisma schema** — define the database before anything touches it
2. **GitHub service** — fetch and parse a real PR diff early, test with real data
3. **Claude service** — nail the prompt and JSON parsing
4. **Express routes** — wire services together into API endpoints
5. **React frontend** — build UI against working API responses

## Coding Conventions
- Always use `async/await`, never raw `.then()` chains
- Never use `any` in TypeScript — always type properly
- Handle errors explicitly — no silent failures
- Keep services thin and focused — one job per file
- Use environment variables for all secrets (API keys, DB URL)
- Never log or store the x-anthropic-key or x-github-token headers

## Communication Style
I am learning as we build. Before writing any code:
- Explain what you are about to do and why
- If introducing a new concept or technology, briefly explain what it is
- After writing code, walk me through the key parts
- If there are multiple ways to do something, tell me which you chose and why
- Flag anything I should understand before we move on

## Environment Variables Needed
```
# backend/.env
DATABASE_URL=        ← provided by Render PostgreSQL
PORT=3000
```
Note: No API keys stored here. Anthropic and GitHub keys come from
the user at runtime via request headers (see BYOK above).

## Deployment (Render)
Three services on Render:
1. **PostgreSQL** — managed DB, provides DATABASE_URL
2. **Web Service** → `/backend` — build: `npm install && npx prisma migrate deploy && npm run build`, start: `npm start`
3. **Static Site** → `/frontend` — build: `npm run build`, publish dir: `dist`
