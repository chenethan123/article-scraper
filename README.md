# Article Scraper

A Dart command-line tool that pulls financial and market news from 30+ RSS feeds, scores each article for market relevance, removes duplicates, and exports the results to **JSON** or a **Google Sheet**.

It was built as the news pipeline behind [MarketAI](#related-projects), a Flutter app that teaches new investors how events move markets.

## How it works

```
RSS feeds ──► parse ──► clean HTML ──► score relevance ──► dedupe ──► export
 (30+ sources)                         (keywords + tickers)          ├─ JSON file
                                                                     └─ Google Sheet (append-only, skips URLs already there)
```

- **Sources:** Reuters, Bloomberg, CNBC, WSJ, MarketWatch, the Federal Reserve, BLS and others (see `lib/config/scraper_config.dart`)
- **Relevance scoring:** matches ~150 market keywords and boosts priority tickers (AAPL, MSFT, AMZN, TSLA, NVDA, SPY)
- **Polite fetching:** a fixed delay between feeds and a descriptive User-Agent
- **Google Sheets export:** authenticates with a service account, creates the worksheet and header row if needed, skips articles whose URL is already in the sheet, and appends the rest in rate-limited batches

## Quick start

```bash
dart pub get

# Print a summary of what's out there right now
dart run bin/scraper_cli.dart --summary

# Export the top 50 articles to JSON
dart run bin/scraper_cli.dart --max-articles 50 -o articles.json

# Only keep highly relevant articles about specific tickers
dart run bin/scraper_cli.dart --tickers AAPL,TSLA --min-score 0.5
```

## Exporting to Google Sheets

1. In Google Cloud, create a service account, enable the **Google Sheets API**, and download its JSON key as `service_account.json` in this folder. This file is gitignored, so never commit it.
2. Share your Google Sheet with the service account's email address (Editor access).
3. Copy the sheet ID from its URL: `docs.google.com/spreadsheets/d/<SHEET_ID>/edit`.
4. Run:

```bash
dart run bin/scraper_cli.dart --sheet-id <SHEET_ID>

# or with environment variables
export GOOGLE_SHEET_ID=<SHEET_ID>
export GOOGLE_SERVICE_ACCOUNT_FILE=path/to/service_account.json
dart run bin/scraper_cli.dart --worksheet "Market News"
```

Each run appends only articles that aren't already in the sheet, so you can schedule it (for example with cron) to build a running news log.

| Published | Title | Source | URL | Relevance | Keywords |
|-----------|-------|--------|-----|-----------|----------|

## CLI options

| Option | Default | Description |
|---|---|---|
| `-o, --output` | — | Write results to a JSON file |
| `--tickers` | — | Comma-separated tickers to focus on |
| `--min-score` | `0.3` | Minimum relevance score (0.0–1.0) |
| `--max-articles` | `100` | Maximum articles to keep |
| `--sheet-id` | `$GOOGLE_SHEET_ID` | Google Sheet to append to |
| `--credentials` | `service_account.json` | Service account key file (or `$GOOGLE_SERVICE_ACCOUNT_FILE`) |
| `--worksheet` | `Articles` | Worksheet (tab) name; created if missing |
| `-s, --summary` | off | Print sources, keywords and averages |

## Project structure

```
bin/scraper_cli.dart              CLI entry point
lib/article_scraper.dart          Orchestrates scraping, dedupe, JSON export
lib/services/rss_scraper.dart     Fetches and parses RSS feeds
lib/utils/content_analyzer.dart   Keyword extraction and relevance scoring
lib/exports/sheets_exporter.dart  Google Sheets export
lib/config/scraper_config.dart    Feeds, keywords, tickers, rate limits
lib/models/article.dart           Article model + JSON serialization
```

## Related projects

**MarketAI** uses this scraper to power its in-app news feed. The Flutter integration (background service and status widget) lives in the MarketAI codebase, so this repo stays a plain Dart package with no Flutter dependency.

**Senior Home Scraper** is a separate Python project that collects senior-living facility contacts from public directories. It isn't in this repo, but the two pipelines are built the same way:

| Stage | Article Scraper (this repo) | Senior Home Scraper |
|---|---|---|
| Collect | RSS feeds (XML) | State health directories, CMS Care Compare, facility websites (HTML) |
| Extract | Title, summary, date, author | Facility name, email addresses |
| Score | Keyword and ticker relevance | Email quality (facility domain over generic) |
| Dedupe | Title + source, then URL against the sheet | Fuzzy name matching against the sheet |
| Export | Batched, append-only Google Sheets writes (logic ported from Senior Home Scraper) | Same, plus an Excel backup |

**Why they aren't one tool:** they share an architecture but nothing else. They're written in different languages (Dart vs Python), read different source formats (structured RSS vs messy HTML pages), produce different records (articles vs contacts), and feed different consumers (a Flutter app vs an outreach spreadsheet). Merging them would mean a shared core so generic that each scraper would need almost entirely custom code anyway. Instead, the Google Sheets export pattern was ported over, because that's the one piece that really is the same.
