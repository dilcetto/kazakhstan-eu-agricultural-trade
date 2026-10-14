# R Extension Validation Results

This file is completed after executing the R refresh and comparing its output with the existing production dataset.

## Execution status

- Initial trial: stopped before output because this R build could not stream `readLines()` directly from an `unz()` connection. The implementation was changed to extract the normalized CSV temporarily and stream the extracted file in bounded chunks.
- First successful run: passed on 2026-10-14
- Second successful run: passed on 2026-10-14
- Final hardening verification run: passed on 2026-10-14
- R version: R 4.3.3
- Retrieval date: 2026-10-14

## Output checks

- Row count: 21
- Coverage: 2018-2024 for `Area harvested`, `Yield` and `Production`
- Duplicate `area + item + element + year` keys: 0
- Missing measurement values: 0
- Units: `ha`, `kg/ha` and `t`, as expected
- Source flags: all 21 records have flag `A` (`Official figure`)
- Flag lookup coverage: all 21 source flags have descriptions
- Metadata paths: repository-relative; no local user path is stored

## Rerun check

- Clean-output SHA-256 after first run: `6e73ac6b170046b7d7079ee8393137896eeea44827f3dc3084a2576acd5b68a5`
- Clean-output SHA-256 after second run: `6e73ac6b170046b7d7079ee8393137896eeea44827f3dc3084a2576acd5b68a5`
- Result: byte-identical clean output. Retrieval metadata changed only where a new run timestamp was expected.

## Existing-pipeline comparison

- Matching records compared: 21 measurements (seven years by three elements)
- Exact value matches: 21
- Maximum absolute numeric difference: 0
- Discrepancies: none. The R long-format output exactly matches the wheat values in `data/processed/prepared_production_data.parquet` after pivoting by element.

## Limitations

- Validation is structural and comparative; it does not independently verify FAO's source statistics.
- A future FAOSTAT release may revise historical values, creating legitimate differences from the existing snapshot.
- The successful runs used the archive available from FAOSTAT on 2026-10-14. The preserved ZIP had 33,921,825 bytes and MD5 `1a202c5674dce152f1134fa87b220b82`.
