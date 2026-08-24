# Leadwise

Leadwise is a small B2B CRM. You describe what your company sells, add prospect companies, and Google Gemini scores how likely each one is to buy from you.

It does **not** scrape websites. Gemini only sees:

- your company description (what you sell)
- the lead’s company name
- the lead’s website URL

The model uses that plus its training knowledge to produce a fit score.

## How it works

1. On the leads page, fill in **Your company** and save it. This is the seller profile used for every score.
2. Click **New Lead**, enter a company name and website, then **Create lead**.
3. Rails saves the lead, then `GeminiScorerService` calls the Gemini API.
4. Gemini returns JSON:
   - **score** — 1–100, likelihood they would buy / take a sales conversation
   - **analysis** — three bullets on fit
   - **objection** — one short sentence on why they might **not** buy
5. The lead opens in a profile popup. Click the company name anytime to reopen it.

**Show prompt** shows the **Your company** text that was used for that score, not the full hidden Gemini prompt.

**Re-evaluate with AI** scores the lead again with the current company profile.

If `GEMINI_API_KEY` is missing, Leadwise still works and uses a mock score (roughly 60–95) so you can try the UI. If the live API errors, a conservative fallback score of 65 is stored and the server log has the details.

## Requirements

- Ruby 3.3 (see `.ruby-version`)
- Bundler
- SQLite

## Setup

```bash
cd leadwise
bundle install
bin/rails db:prepare
```

Optional sample leads (Stripe, Shopify, Acme Corp):

```bash
bin/rails db:seed
```

## Gemini API key

Live scoring reads **only** the environment variable `GEMINI_API_KEY`.  
Do not put the key in the repo, `README`, credentials files, or the Rails UI.

1. Create a key at [Google AI Studio](https://aistudio.google.com/apikey).
2. Set it in the **same terminal** you use to start the server, then start Rails.

### Windows (PowerShell)

```powershell
$env:GEMINI_API_KEY = "your-key-here"
ruby bin/rails server
```

To keep it across terminal sessions, add a User environment variable named `GEMINI_API_KEY` in Windows Settings, then open a **new** terminal and start the server.

### macOS / Linux

```bash
export GEMINI_API_KEY="your-key-here"
bin/rails server
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000). A live score notices **Lead was created with Gemini.** Without a key, the notice says mock scoring is in use because `GEMINI_API_KEY` is not set.

The key is sent as the `x-goog-api-key` header (not in the URL). Restart the server after changing the variable.

## Daily use

| You do | Leadwise does |
| --- | --- |
| Save **Your company** | Stores the seller profile used for scoring |
| Create a lead | Saves name + website, then scores with Gemini |
| Open a lead | Shows fit score, three fit bullets, and why they might not buy |
| Re-evaluate with AI | Scores again with the latest company profile |
| Show prompt | Shows the company description used for that score |

Creating or re-evaluating a lead can take a few seconds. The form shows a spinner while Gemini runs.

## Tests

```bash
bin/rails test
```

## Project layout

- `app/models/lead.rb` — leads (name, website, score, analysis, objection)
- `app/models/setting.rb` — singleton **Your company** description
- `app/services/gemini_scorer_service.rb` — Gemini (or mock/fallback) scoring
- `app/controllers/leads_controller.rb` — CRUD + re-score
- `db/migrate/` — SQLite schema

Data lives in `storage/development.sqlite3` (not committed).
