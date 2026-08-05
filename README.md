Data Quality Notes

* No duplicate rows were found in either dataset.
* Column names were standardized to lowercase with underscores.
* Text fields were stripped of leading/trailing whitespace.
* Numeric fields (year, value) were converted to numeric types.
* Missing values in the trade dataset correspond to country–partner–commodity–year combinations with no reported exports.
* Missing values in the production dataset primarily affect the Extraction Rate element, which is not applicable or unavailable for many commodities.
* No rows were removed during the cleaning phase; project-specific filtering is performed later during dataset preparation.
* Some processed commodities (e.g. crude vegetable oils) do not have agricultural yield or harvested area. These missing values are expected and are preserved.