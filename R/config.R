# Config loader: the only place that reads projekt.yml. All other modules call cfg().
# Validation fails early with a readable message instead of a crash after hours of scraping.

config_laden <- function(pfad = Sys.getenv("PROJEKT_YML", "projekt.yml")) {
  if (!file.exists(pfad)) stop("No ", pfad, ". Run `Rscript setup.R` or copy projekt.example.yml to projekt.yml.", call. = FALSE)
  c <- yaml::read_yaml(pfad)
  fehler <- config_pruefen(c)
  if (length(fehler)) stop("Invalid ", pfad, ":\n - ", paste(fehler, collapse = "\n - "), call. = FALSE)
  c$time$overall$start <- as.Date(c$time$overall$start)
  c$time$overall$end   <- as.Date(c$time$overall$end)
  for (i in seq_along(c$time$windows)) {
    c$time$windows[[i]]$start <- as.Date(c$time$windows[[i]]$start)
    c$time$windows[[i]]$end   <- as.Date(c$time$windows[[i]]$end)
  }
  c
}

config_pruefen <- function(c) {
  f <- character()
  need <- function(ok, msg) if (!isTRUE(ok)) f <<- c(f, msg)
  need(nzchar(c$project$contact %||% ""), "project.contact is required (goes into the User-Agent)")
  need(length(c$topic$keywords) > 0, "topic.keywords needs at least one language")
  need(all(vapply(c$topic$keywords, \(k) length(k) > 0, logical(1))), "every keyword language needs at least one term")
  ok_re <- all(vapply(unlist(c$topic$keywords), \(r) !inherits(try(grepl(r, "", perl = TRUE), silent = TRUE), "try-error"), logical(1)))
  need(ok_re, "topic.keywords contains an invalid regular expression")
  von <- suppressWarnings(as.Date(c$time$overall$start)); bis <- suppressWarnings(as.Date(c$time$overall$end))
  need(!is.na(von) && !is.na(bis) && von < bis, "time.overall.start/end must be dates with start < end")
  for (w in c$time$windows) {
    ws <- suppressWarnings(as.Date(w$start)); we <- suppressWarnings(as.Date(w$end))
    need(!is.na(ws) && !is.na(we) && ws <= we, paste0("window ", w$id %||% "?", ": invalid dates"))
    if (!is.na(ws) && !is.na(von) && !is.na(bis)) need(ws >= von && we <= bis, paste0("window ", w$id %||% "?", " lies outside time.overall"))
  }
  need(length(c$sources$outlets) > 0, "sources.outlets needs at least one outlet")
  for (o in c$sources$outlets) {
    need(all(c("name", "domain", "country", "language") %in% names(o)), paste0("outlet ", o$name %||% "?", ": name, domain, country, language required"))
    need(o$language %in% names(c$topic$keywords), paste0("outlet ", o$name %||% "?", ": no keywords for language '", o$language, "'"))
  }
  need(c$translation$engine %in% c("nllb", "none"), "translation.engine must be nllb or none")
  f
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Cached accessor: cfg()$topic$keywords
cfg <- local({ obj <- NULL; function(neu = FALSE) { if (is.null(obj) || neu) obj <<- config_laden(); obj } })

# Derived values the pipeline needs (so no module builds them itself)
keywords_regex <- function(c = cfg()) {
  stats::setNames(lapply(c$topic$keywords, \(k) paste(k, collapse = "|")), names(c$topic$keywords))
}
analysefenster <- function(c = cfg()) {
  w <- c$time$windows
  if (!length(w)) return(data.frame(id = "ALL", start = c$time$overall$start, end = c$time$overall$end, label = "whole period"))
  do.call(rbind, lapply(w, \(x) data.frame(id = x$id, start = x$start, end = x$end, label = x$label %||% "")))
}
