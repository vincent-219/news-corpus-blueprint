# news-corpus-blueprint

A reproducible, resumable pipeline for **comparative newspaper analysis in many languages**:
find articles → download full texts politely → import and de-duplicate → translate → build an analysis corpus,
with a live dashboard and watchdogs for every long-running job.

It grew out of a master's thesis on the coverage of the Israel–Gaza war in about 55 countries
(University of Stuttgart). The thesis topic is *one configuration* of this framework; the framework itself is
meant to be reused for any topic, period and set of outlets.

## What you configure (and only this)

Everything topic-specific lives in `projekt.yml` (template: `projekt.example.yml`):
keywords per language, overall period and analysis windows, outlets with country and language,
translation engine, resource limits. `Rscript setup.R` asks for these interactively and validates the file.

## Pipeline

| Stage | What happens | Guards |
|---|---|---|
| 1 Collect URLs | sitemaps, Media Cloud (weekly quota aware), archive pages | robots.txt, crawl delay, resumable |
| 2 Download texts | polite, per outlet, paywall detection | memory ceiling, disk watcher |
| 3 Import | SQLite, id = hash(outlet, date, title), de-duplication | idempotent |
| 4 Translate | local NLLB on GPU, title / lead / first half page | auto-restart |
| 5 Corpus | relevance-filtered, English/translated analysis corpus | |
| 6 Optional: Nexis Uni export | for paywalled outlets, supervised browser runs | stops on any block |
| Live dashboard | progress per stage, coverage by country, pace | heartbeat + stall detection |

See `docs/ARCHITECTURE.md` (design and the supervision rules) and `docs/MIGRATION.md` (how the thesis code maps
onto the config).

## Where to start

1. Read this page, then `docs/ARCHITECTURE.md` (design and the supervision rules, one page).
2. Look at `projekt.example.yml` to see what a project configuration contains.
3. To see the pipeline running on a real topic, open the thesis repository
   [`vincent-219/masterarbeit_presentable`](https://github.com/vincent-219/masterarbeit_presentable)
   (README in English: `README_en.md`). The blueprint is the topic-free version of that code.

## Workflow

Die Pipeline ist als Snakemake-Workflow beschrieben (ein Graph für dein Thema, je Medium und Sprache): [workflow/README.md](workflow/README.md).

## Status

Early stage. Done so far: config loader with validation (`R/config.R`) and interactive `setup.R`.
The other stages exist only in the thesis repository above and are being generalised step by step
(see `docs/MIGRATION.md`). Nothing here is production-ready yet.
