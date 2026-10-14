#!/usr/bin/env Rscript

# Refresh a small FAOSTAT production subset used by the existing project.
#
# Scope: Kazakhstan, wheat, 2018-2024, for Production, Area harvested and Yield.
# Dependencies: base R only.

SOURCE_URL <- paste0(
  "https://bulks-faostat.fao.org/production/",
  "Production_Crops_Livestock_E_All_Data_(Normalized).zip"
)
ARCHIVE_NAME <- "Production_Crops_Livestock_E_All_Data_(Normalized).zip"
OUTPUT_NAME <- "r_kazakhstan_wheat_production_2018_2024.csv"
METADATA_NAME <- "r_kazakhstan_wheat_production_metadata.csv"

TARGET_AREA <- "Kazakhstan"
TARGET_ITEM <- "Wheat"
TARGET_YEARS <- 2018:2024
TARGET_ELEMENTS <- c("Area harvested", "Yield", "Production")
EXPECTED_UNITS <- c(
  "Area harvested" = "ha",
  "Yield" = "kg/ha",
  "Production" = "t"
)
CHUNK_SIZE <- 100000L

stop_with <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

script_path <- function() {
  file_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_argument) != 1L) {
    stop_with("Could not determine the script path. Run this file with Rscript.")
  }
  normalizePath(sub("^--file=", "", file_argument), mustWork = TRUE)
}

project_root <- normalizePath(
  file.path(dirname(script_path()), ".."),
  mustWork = TRUE
)
raw_dir <- file.path(project_root, "data", "raw", "r_faostat_production")
processed_dir <- file.path(project_root, "data", "processed")
archive_path <- file.path(raw_dir, ARCHIVE_NAME)
output_path <- file.path(processed_dir, OUTPUT_NAME)
metadata_path <- file.path(processed_dir, METADATA_NAME)

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

clean_column_names <- function(column_names) {
  cleaned <- tolower(trimws(column_names))
  cleaned <- gsub("[^a-z0-9]+", "_", cleaned)
  cleaned <- gsub("^_+|_+$", "", cleaned)
  cleaned
}

assert_required_columns <- function(data, required, context) {
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0L) {
    stop_with(
      "%s is missing required columns: %s",
      context,
      paste(missing_columns, collapse = ", ")
    )
  }
}

atomic_write_csv <- function(data, destination) {
  temporary <- tempfile(
    pattern = paste0(basename(destination), "."),
    tmpdir = dirname(destination),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  utils::write.csv(data, temporary, row.names = FALSE, na = "")
  if (!file.copy(temporary, destination, overwrite = TRUE)) {
    stop_with("Could not replace output file: %s", destination)
  }
}

find_archive_member <- function(archive, pattern, label) {
  listing <- utils::unzip(archive, list = TRUE)
  matches <- listing$Name[grepl(pattern, listing$Name)]
  if (length(matches) != 1L) {
    stop_with(
      "Expected one %s file in the archive, found %d.",
      label,
      length(matches)
    )
  }
  matches
}

download_archive <- function(url, destination) {
  temporary <- tempfile(
    pattern = "faostat-production-",
    tmpdir = dirname(destination),
    fileext = ".zip"
  )
  on.exit(unlink(temporary), add = TRUE)

  message("Downloading official FAOSTAT archive:")
  message("  ", url)
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(600, old_timeout))

  status <- tryCatch(
    utils::download.file(
      url = url,
      destfile = temporary,
      mode = "wb",
      method = "libcurl",
      quiet = FALSE
    ),
    error = function(error) {
      stop_with(
        paste0(
          "FAOSTAT download failed: %s\n",
          "The previous archive, if present, was not reused."
        ),
        conditionMessage(error)
      )
    }
  )

  if (!identical(status, 0L) || !file.exists(temporary)) {
    stop_with(
      "FAOSTAT download failed with status %s. No stale archive was reused.",
      as.character(status)
    )
  }
  if (file.info(temporary)$size <= 0) {
    stop_with("FAOSTAT download produced an empty file.")
  }

  tryCatch(
    utils::unzip(temporary, list = TRUE),
    error = function(error) {
      stop_with("Downloaded file is not a readable ZIP archive: %s", conditionMessage(error))
    }
  )

  if (!file.copy(temporary, destination, overwrite = TRUE)) {
    stop_with("Could not preserve the downloaded archive at: %s", destination)
  }

  message("Saved original archive to: ", destination)
}

read_lookup_file <- function(path) {
  connection <- file(path, open = "rt", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  lookup <- utils::read.csv(
    connection,
    check.names = FALSE,
    colClasses = "character",
    na.strings = c("", "NA"),
    strip.white = TRUE
  )
  names(lookup) <- clean_column_names(names(lookup))
  lookup
}

read_target_subset <- function(csv_path) {
  required_source_columns <- c(
    "area_code",
    "area_code_m49",
    "area",
    "item_code",
    "item_code_cpc",
    "item",
    "element_code",
    "element",
    "year",
    "unit",
    "value",
    "flag",
    "note"
  )

  connection <- file(csv_path, open = "rt", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)

  header_line <- readLines(connection, n = 1L, warn = FALSE)
  if (length(header_line) != 1L) {
    stop_with("The normalized FAOSTAT CSV has no header row.")
  }

  header_connection <- textConnection(header_line)
  header <- utils::read.csv(
    header_connection,
    nrows = 0L,
    check.names = FALSE,
    colClasses = "character"
  )
  close(header_connection)
  names(header) <- clean_column_names(names(header))
  assert_required_columns(header, required_source_columns, "FAOSTAT normalized CSV")

  selected_chunks <- list()
  selected_count <- 0L
  lines_processed <- 0L

  repeat {
    lines <- readLines(connection, n = CHUNK_SIZE, warn = FALSE)
    if (length(lines) == 0L) {
      break
    }

    chunk_connection <- textConnection(c(header_line, lines))
    chunk <- utils::read.csv(
      chunk_connection,
      check.names = FALSE,
      colClasses = "character",
      na.strings = c("", "NA"),
      strip.white = TRUE
    )
    close(chunk_connection)
    names(chunk) <- clean_column_names(names(chunk))

    keep <- !is.na(chunk$area) & chunk$area == TARGET_AREA &
      !is.na(chunk$item) & chunk$item == TARGET_ITEM &
      !is.na(chunk$element) & chunk$element %in% TARGET_ELEMENTS &
      !is.na(chunk$year) & chunk$year %in% as.character(TARGET_YEARS)

    if (any(keep)) {
      selected_count <- selected_count + 1L
      selected_chunks[[selected_count]] <- chunk[keep, required_source_columns, drop = FALSE]
    }

    lines_processed <- lines_processed + length(lines)
    if (lines_processed %% 1000000L < CHUNK_SIZE) {
      message("Read ", format(lines_processed, big.mark = ","), " source rows...")
    }
  }

  if (length(selected_chunks) == 0L) {
    stop_with(
      "No records matched %s / %s / %d-%d.",
      TARGET_AREA,
      TARGET_ITEM,
      min(TARGET_YEARS),
      max(TARGET_YEARS)
    )
  }

  do.call(rbind, selected_chunks)
}

read_archive_subset <- function(archive, data_member, flags_member) {
  extraction_dir <- tempfile(pattern = "faostat-production-extract-")
  dir.create(extraction_dir, recursive = TRUE)
  on.exit(unlink(extraction_dir, recursive = TRUE, force = TRUE), add = TRUE)

  message("Temporarily extracting normalized data for chunked reading...")
  extracted <- tryCatch(
    utils::unzip(
      archive,
      files = c(data_member, flags_member),
      exdir = extraction_dir,
      overwrite = TRUE
    ),
    error = function(error) {
      stop_with("Could not extract FAOSTAT archive members: %s", conditionMessage(error))
    }
  )

  data_path <- file.path(extraction_dir, data_member)
  flags_path <- file.path(extraction_dir, flags_member)
  if (!all(file.exists(c(data_path, flags_path)))) {
    stop_with(
      "Archive extraction did not create the expected files. Extracted: %s",
      paste(extracted, collapse = ", ")
    )
  }

  list(
    raw_subset = read_target_subset(data_path),
    flag_lookup = read_lookup_file(flags_path)
  )
}

clean_and_validate <- function(raw_subset, flag_lookup) {
  character_columns <- names(raw_subset)[vapply(raw_subset, is.character, logical(1))]
  raw_subset[character_columns] <- lapply(
    raw_subset[character_columns],
    function(values) {
      values <- trimws(values)
      values[values == ""] <- NA_character_
      values
    }
  )

  year <- suppressWarnings(as.integer(raw_subset$year))
  if (any(!is.na(raw_subset$year) & is.na(year))) {
    stop_with("The selected subset contains non-numeric year values.")
  }

  value <- suppressWarnings(as.numeric(raw_subset$value))
  if (any(!is.na(raw_subset$value) & is.na(value))) {
    stop_with("The selected subset contains non-numeric measurement values.")
  }

  assert_required_columns(flag_lookup, c("flag", "description"), "FAOSTAT flag lookup")
  flag_description <- flag_lookup$description[match(raw_subset$flag, flag_lookup$flag)]
  unknown_flags <- unique(raw_subset$flag[
    !is.na(raw_subset$flag) & is.na(flag_description)
  ])
  if (length(unknown_flags) > 0L) {
    stop_with(
      "The selected subset contains flags missing from the lookup: %s.",
      paste(unknown_flags, collapse = ", ")
    )
  }

  clean <- data.frame(
    area_code = raw_subset$area_code,
    area_code_m49 = raw_subset$area_code_m49,
    area = raw_subset$area,
    item_code = raw_subset$item_code,
    item_code_cpc = raw_subset$item_code_cpc,
    item = raw_subset$item,
    element_code = raw_subset$element_code,
    element = raw_subset$element,
    year = year,
    unit = raw_subset$unit,
    value = value,
    flag = raw_subset$flag,
    flag_description = flag_description,
    note = raw_subset$note,
    stringsAsFactors = FALSE
  )

  key_columns <- c("area", "item", "element", "year")
  duplicate_rows <- duplicated(clean[key_columns])
  if (any(duplicate_rows)) {
    stop_with(
      "Found %d duplicate records for key: %s.",
      sum(duplicate_rows),
      paste(key_columns, collapse = ", ")
    )
  }

  expected_keys <- as.vector(outer(
    TARGET_ELEMENTS,
    TARGET_YEARS,
    function(element, year_value) paste(element, year_value, sep = "|")
  ))
  actual_keys <- paste(clean$element, clean$year, sep = "|")
  missing_keys <- setdiff(expected_keys, actual_keys)
  unexpected_keys <- setdiff(actual_keys, expected_keys)
  if (length(missing_keys) > 0L || length(unexpected_keys) > 0L) {
    stop_with(
      "Coverage check failed. Missing: [%s]. Unexpected: [%s].",
      paste(missing_keys, collapse = ", "),
      paste(unexpected_keys, collapse = ", ")
    )
  }

  if (any(is.na(clean$value))) {
    stop_with("The selected subset contains %d missing values.", sum(is.na(clean$value)))
  }

  for (element_name in names(EXPECTED_UNITS)) {
    observed_units <- unique(clean$unit[clean$element == element_name])
    if (!identical(observed_units, unname(EXPECTED_UNITS[[element_name]]))) {
      stop_with(
        "Unexpected unit for %s: expected %s, found %s.",
        element_name,
        EXPECTED_UNITS[[element_name]],
        paste(observed_units, collapse = ", ")
      )
    }
  }

  order_index <- order(clean$year, match(clean$element, TARGET_ELEMENTS))
  clean[order_index, , drop = FALSE]
}

write_metadata <- function(clean_data, archive, data_member, flags_member) {
  retrieved_at_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  metadata <- data.frame(
    field = c(
      "retrieved_at_utc",
      "source_url",
      "access_method",
      "source_update_frequency",
      "archive_path",
      "archive_size_bytes",
      "archive_md5",
      "normalized_data_member",
      "flags_member",
      "output_path",
      "output_rows",
      "first_year",
      "last_year",
      "elements",
      "r_version"
    ),
    value = c(
      retrieved_at_utc,
      SOURCE_URL,
      "Official FAOSTAT bulk ZIP download; full normalized file is filtered locally",
      "Annual",
      file.path("data", "raw", "r_faostat_production", ARCHIVE_NAME),
      as.character(file.info(archive)$size),
      unname(tools::md5sum(archive)),
      data_member,
      flags_member,
      file.path("data", "processed", OUTPUT_NAME),
      as.character(nrow(clean_data)),
      as.character(min(clean_data$year)),
      as.character(max(clean_data$year)),
      paste(sort(unique(clean_data$element)), collapse = "; "),
      R.version.string
    ),
    stringsAsFactors = FALSE
  )
  atomic_write_csv(metadata, metadata_path)
}

message("FAOSTAT R refresh")
message("Project root: ", project_root)
message("Subset: Kazakhstan / Wheat / 2018-2024")

download_archive(SOURCE_URL, archive_path)
data_member <- find_archive_member(
  archive_path,
  "All_Data_\\(Normalized\\)\\.csv$",
  "normalized data"
)
flags_member <- find_archive_member(archive_path, "_Flags\\.csv$", "flags lookup")

archive_data <- read_archive_subset(archive_path, data_member, flags_member)
clean_data <- clean_and_validate(
  archive_data$raw_subset,
  archive_data$flag_lookup
)

atomic_write_csv(clean_data, output_path)
write_metadata(clean_data, archive_path, data_member, flags_member)

message("Validation passed:")
message("  rows: ", nrow(clean_data))
message("  years: ", min(clean_data$year), "-", max(clean_data$year))
message("  elements: ", paste(sort(unique(clean_data$element)), collapse = ", "))
message("  duplicate record keys: 0")
message("  missing measurement values: 0")
message("Wrote clean output to: ", output_path)
message("Wrote retrieval metadata to: ", metadata_path)
