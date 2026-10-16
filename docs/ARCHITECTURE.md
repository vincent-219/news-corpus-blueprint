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

**Graph for the batch part only:** bulk work that depends on files (translation and quality check on a cluster) is a Snakemake
graph: each rule declares inputs and outputs, packages become parallel Slurm jobs, a finished output is never recomputed.
Services that run continuously (collecting, import, relevance) are loops under supervision, not part of the graph.

**Quality check:** translations are scored by an agreement classifier. The label comes from a second, independent model where it
covers the language; otherwise from a back-translation (English text translated back into the source language and compared with
the original). The back-translation shares the model with the forward direction, so it is a weaker reference: calibrate it on
languages where both references exist before relying on it. The result is a flag; the main analysis stays on the full corpus.
