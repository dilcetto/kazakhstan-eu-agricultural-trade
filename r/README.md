# R FAOSTAT Wheat Production Refresh

## Purpose and scope

This small extension reimplements one existing production-data workflow in base R. It retrieves the official FAOSTAT **Crops and livestock products** bulk archive, then selects Kazakhstan wheat records for 2018-2024 and the three series already used by the Python pipeline:

- `Area harvested` in hectares;
- `Yield` in kilograms per hectare; and
- `Production` in tonnes.

It does not replace or modify the existing Python, SQL, notebook or Tableau workflows.

## Official source and access method

- Dataset: FAOSTAT Crops and livestock products, production domain (`QCL`).
- Official bulk archive: <https://bulks-faostat.fao.org/production/Production_Crops_Livestock_E_All_Data_(Normalized).zip>
- FAOSTAT portal: <https://www.fao.org/faostat/>
- Dataset metadata: <https://www.fao.org/faostat/en/#data/QCL/metadata>
- Documented update frequency: annual. FAO's agricultural-production release page identifies the release interval as annual: <https://www.fao.org/statistics/events/events-detail/agricultural-production-statistics-2010-2023/>

FAOSTAT does not provide a small commodity-specific file at the bulk-download URL used here. The script downloads the complete compressed production archive (about 34 MB at the retrieval recorded in this repository), temporarily extracts its roughly 545 MB normalized CSV, and reads that file in chunks before keeping only 21 required records. The original ZIP is preserved locally; the temporary extracted copy is removed after reading.

## Dependencies

- R 4.3 or later recommended.
- Internet access.
- Base R only; no additional R packages are required.

Run from any directory with:

```bash
Rscript r/update_kazakhstan_wheat_production.R
```

## Files and folders

```text
r/
├── README.md
├── source_documentation.csv
├── update_kazakhstan_wheat_production.R
└── validation_results.md
data/
├── raw/
│   └── r_faostat_production/
│       └── Production_Crops_Livestock_E_All_Data_(Normalized).zip
└── processed/
    ├── r_kazakhstan_wheat_production_2018_2024.csv
    └── r_kazakhstan_wheat_production_metadata.csv
```

The downloaded archive is ignored by Git because it is a large reproducible source file. The clean CSV and retrieval metadata are small.

## Refresh and rerun behaviour

The latest verified retrieval date is **2026-10-14**. Each run:

1. downloads the official archive to a temporary file;
2. validates that it is a readable ZIP;
3. replaces the preserved raw archive only after a successful download;
4. filters and validates the requested records; and
5. overwrites, rather than appends to, the clean output and metadata files.

The script never silently falls back to an older local archive. If downloading fails, it exits with a clear error and leaves any previous archive untouched.

## Validation checks

The script stops without replacing the clean output when any of these checks fail:

- required source columns are missing;
- Kazakhstan, wheat or the requested series are unavailable;
- coverage is not exactly 2018-2024 for all three elements;
- duplicate `area + item + element + year` keys are present;
- measurement values are missing or non-numeric; or
- units differ from `ha`, `kg/ha` and `t` for the expected elements.

The output preserves FAOSTAT area, item and element codes, units, source flags, flag descriptions and notes. See [`validation_results.md`](validation_results.md) for the latest execution and comparison results.

## How the script works and the R concepts involved

1. **Constants and vectors:** target years, elements and expected units are stored in vectors so the scope is visible and easy to change.
2. **Functions:** downloading, name cleaning, chunk reading, validation and writing are separate functions with one responsibility each.
3. **Connections:** `file()` opens the temporarily extracted normalized CSV and `readLines()` streams it in chunks, keeping memory use bounded.
4. **Data frames and logical filtering:** each chunk is parsed as character data and filtered with Boolean conditions before rows are combined.
5. **Explicit coercion:** `year` is converted to integer and `value` to numeric. Failed coercions are treated as errors rather than silently converted to missing values.
6. **Keys and duplicates:** `duplicated()` checks the expected record key before output is written.
7. **Named vectors:** expected units are stored by element name and checked in a short loop.
8. **Deterministic output:** `write.csv()` writes a temporary file that replaces the prior output, preventing accidental appends.
9. **Error handling:** `tryCatch()` turns download and ZIP problems into readable failure messages.

## Known limitations

- The script downloads the full production archive even though only 21 records are retained.
- A refresh temporarily needs about 600 MB of free disk space for the archive and extracted CSV.
- Historical FAOSTAT observations may be revised in later annual releases, so rerun results can legitimately differ from committed snapshots.
- Validation confirms structure and internal expectations; it does not independently audit FAO's underlying national statistics.
- The script selects English labels. A future label change could require updating the target strings.
- Network proxies, certificate inspection or temporary FAOSTAT outages can block the download.

## Troubleshooting

- **Download fails:** confirm that the bulk URL opens in a browser and that R can access HTTPS. Rerun later if FAOSTAT is temporarily unavailable.
- **Timeout:** the script allows up to 600 seconds; retry on a stable connection if the archive still times out.
- **Coverage or unit check fails:** inspect FAOSTAT release notes and the preserved archive instead of weakening the checks.
- **Archive should not be committed:** confirm `git status --ignored` shows the ZIP as ignored.

## Development note

AI assisted with source research, code drafting and review, and documentation. The workflow was executed and validated locally. This is a portfolio learning exercise, not WHO work or professional employment.

## Practice before presenting this work

1. Change `TARGET_ITEM` from `Wheat` to `Linseed`, run the script and explain any difference in coverage or flags.
2. Extend `TARGET_YEARS` by one year and explain why the coverage check should fail if FAOSTAT has not published that year.
3. Explain why the script initially reads source fields as character data before explicitly converting `year` and `value`.
4. Identify the composite record key and describe what a duplicate would do to an analysis if it were not rejected.
5. Add a short console summary showing production in the first and last selected years without changing the clean output schema.
