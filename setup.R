#!/usr/bin/env Rscript
# Interactive setup: asks the topic-specific questions and writes projekt.yml (validated).
source("R/config.R")
ask <- function(q, default = "") { a <- trimws(readline(sprintf("%s%s: ", q, if (nzchar(default)) sprintf(" [%s]", default) else ""))); if (nzchar(a)) a else default }
split_list <- function(x) trimws(strsplit(x, ",")[[1]])

if (!interactive() && !nzchar(Sys.getenv("SETUP_FORCE"))) {
  con <- file("stdin"); on.exit(close(con)); readline <- function(prompt) { cat(prompt); readLines(con, 1) }
}
cat("news-corpus-blueprint setup (Enter keeps the default)\n\n")
c <- yaml::read_yaml("projekt.example.yml")
c$project$name    <- ask("Project name", "my-news-study")
c$project$contact <- ask("Contact for the User-Agent (name, institution <mail>)")
langs <- split_list(ask("Languages of your outlets (ISO codes, comma separated)", "en,de"))
c$topic$keywords <- stats::setNames(lapply(langs, \(l) split_list(ask(sprintf("Keywords (regex) in '%s', comma separated", l)))), langs)
c$time$overall <- list(start = ask("Period start (YYYY-MM-DD)", "2023-01-01"), end = ask("Period end (YYYY-MM-DD)", "2025-12-31"))
c$time$windows <- list()
repeat {
  id <- ask("Analysis window id (empty = done)"); if (!nzchar(id)) break
  c$time$windows[[length(c$time$windows) + 1]] <- list(id = id, start = ask("  start"), end = ask("  end"), label = ask("  label"))
}
c$sources$outlets <- list()
repeat {
  n <- ask("Outlet name (empty = done)"); if (!nzchar(n)) break
  c$sources$outlets[[length(c$sources$outlets) + 1]] <- list(name = n, domain = ask("  domain"), country = ask("  country (ISO2)"), language = ask("  language", langs[1]))
}
tmp <- tempfile(fileext = ".yml"); yaml::write_yaml(c, tmp)
fehler <- tryCatch({ config_laden(tmp); character() }, error = function(e) conditionMessage(e))
if (length(fehler)) { cat("\nNot written.\n", fehler, "\n"); quit(status = 1) }
file.copy(tmp, "projekt.yml", overwrite = TRUE); cat("\nWrote projekt.yml\n")
