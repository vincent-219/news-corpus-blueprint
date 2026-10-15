# Architecture

**Principle:** code is topic-free; the topic is data (`projekt.yml`). Every module reads the config through one
loader (`R/config.R`), never from constants.

**Supervision rule:** every job that runs unattended writes a heartbeat (`data/live/*.json`), classifies failures
(exit 3 = hard stop, never restart: captcha, block, limit, expired login, wrong network route; exit 4 = transient,
restart after a pause, max 5 per hour), is resumable, and shows up in the live dashboard.

**Politeness rule:** robots.txt, a contact User-Agent, crawl delays, no circumvention of paywalls or bot protection
(paywalled outlets go through licensed access such as Nexis Uni).

**Data flow:** `data/raw/urls` → `data/raw/scraper` (CSV per outlet) → `data/korpus.sqlite`
(`artikel`, `uebersetzung`, `lauf_log`) → analysis corpus.
