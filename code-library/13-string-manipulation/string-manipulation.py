# ==============================================================================
#  MODULE 13: STRING MANIPULATION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: pandas (str accessor), re (regex), numpy
#  All string operations use the pd.Series.str accessor where possible.
# ==============================================================================

import pandas as pd
import numpy as np
import re

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: CASE CONVERSION
# ==============================================================================

# Simulate a messy name/label column
ces["race_label"] = ces["race_eth"].map({
    1: "White Non-Hispanic",
    2: "Black Non-Hispanic",
    3: "Hispanic",
    4: "asian non-hispanic",   # intentionally messy
    5: "MIXED RACE",
    6: "other",
    8: np.nan,
    9: np.nan,
})

ces["race_lower"] = ces["race_label"].str.lower()
ces["race_upper"] = ces["race_label"].str.upper()
ces["race_title"] = ces["race_label"].str.title()   # Title Case

print("Case conversions (first 6 distinct):")
print(
    ces[["race_label", "race_lower", "race_upper", "race_title"]]
    .drop_duplicates()
    .dropna()
    .to_string(index=False)
)


# ==============================================================================
# SECTION 2: TRIMMING AND PADDING
# ==============================================================================

# Simulate a state abbreviation column with extra whitespace
state_abbrev = pd.Series([" FL", "GA ", " TX ", "NY", "CA"])

state_clean = state_abbrev.str.strip()
print("\nBefore strip:", state_abbrev.tolist())
print("After strip: ", state_clean.tolist())

# str.strip()   — remove both ends
# str.lstrip()  — remove left only
# str.rstrip()  — remove right only

# Padding: zero-pad state FIPS codes to 2 digits
# pd.Series.str.zfill(width) pads with zeros on the left
fips_sample = pd.Series([1, 2, 4, 6, 12, 36, 48]).astype(str)
fips_padded = fips_sample.str.zfill(2)
print("\nFIPS padding:")
print(pd.DataFrame({"raw": fips_sample, "padded": fips_padded}).to_string(index=False))

# Left-justify with str.ljust() / right-justify with str.rjust()
labels = pd.Series(["age", "education", "ideology5"])
print("\nLeft-padded to width 15:")
print(labels.str.ljust(15, fillchar=".").tolist())


# ==============================================================================
# SECTION 3: SUBSTRINGS
# ==============================================================================

# str[start:stop] via str accessor — same slice syntax as Python strings
ces["race_first3"] = ces["race_label"].str[:3]

print("\nFirst 3 characters of race_label:")
print(ces[["race_label","race_first3"]].drop_duplicates().dropna().to_string(index=False))

# Extract the first word (everything before the first space)
ces["race_word1"] = ces["race_label"].str.split().str[0]

# str.find() equivalent: str.index — use str.find() returns -1 if not found
space_pos = ces["race_label"].str.find(" ")
print("\nPosition of first space in race_label (first 5 rows):")
print(space_pos.dropna().head().tolist())


# ==============================================================================
# SECTION 4: DETECTION  (str.contains / str.startswith / str.endswith)
# ==============================================================================

# str.contains(): returns True/False (NaN-safe with na=False)
ces["is_hispanic"] = ces["race_label"].str.contains("Hispanic", case=False, na=False)
ces["starts_w"]    = ces["race_label"].str.startswith("W", na=False)
ces["ends_ic"]     = ces["race_label"].str.endswith("ic", na=False)

print("\nDetection checks (first 6 distinct):")
print(
    ces[["race_label","is_hispanic","starts_w","ends_ic"]]
    .drop_duplicates()
    .dropna(subset=["race_label"])
    .to_string(index=False)
)

# Regex detection with str.match() (anchored at start) or str.contains(regex=True)
ces["is_mixed"] = ces["race_label"].str.contains(r"mixed|multi", case=False, na=False)


# ==============================================================================
# SECTION 5: REPLACE AND SUBSTITUTE
# ==============================================================================

# str.replace() — works with literal strings or regex
ces["race_clean"] = (
    ces["race_label"]
    .str.replace("Non-Hispanic", "NH", regex=False)
    .str.replace(r"\s+", " ", regex=True)   # collapse multiple spaces
    .str.strip()
)

print("\nAfter replace (first 6 distinct):")
print(
    ces[["race_label","race_clean"]]
    .drop_duplicates()
    .dropna()
    .to_string(index=False)
)

# str.replace with a function (callable)
# Example: capitalize only the first letter of each word
ces["race_sentence"] = ces["race_label"].str.lower().str.capitalize()


# ==============================================================================
# SECTION 6: SPLITTING AND JOINING
# ==============================================================================

# Simulate a "first last" name column
ces["full_name"] = "Respondent " + ces["caseid"].astype(str)

# str.split() returns a list per cell; use expand=True to get separate columns
name_split = ces["full_name"].str.split(" ", expand=True)
name_split.columns = ["name_part1", "name_part2"]

print("\nSplit names (first 5):")
print(name_split.head())

# Simulate a date string column (e.g., "2020-11-03")
ces["interview_date"] = "2020-11-" + ces["caseid"].mod(28).add(1).astype(str).str.zfill(2)

date_parts = ces["interview_date"].str.split("-", expand=True)
date_parts.columns = ["year", "month", "day"]

print("\nDate parts (first 5):")
print(date_parts.head())

# Joining: str.cat() concatenates series element-wise
state_fips_str = ces["state_fips"].astype(str).str.zfill(2)
ces["geo_id"] = "US" + state_fips_str


# ==============================================================================
# SECTION 7: REGEX EXTRACTION
# ==============================================================================

# str.extract() with named capture groups — returns a DataFrame of captures
sample_ids = pd.Series(["ID-001-FL", "ID-204-GA", "ID-089-TX", "ID-543-NY"])

extracted = sample_ids.str.extract(r"ID-(?P<num>\d+)-(?P<state>[A-Z]{2})")
print("\nRegex extraction:")
print(extracted)

# Extract just the numeric part from a single pattern
nums_only = sample_ids.str.extract(r"(\d+)", expand=False)
print("\nNumbers only:", nums_only.tolist())

# str.extractall() — all non-overlapping matches (useful for repeated patterns)
text_series = pd.Series(["age=30 sex=1", "age=45 sex=2", "age=22 sex=1"])
all_matches = text_series.str.extractall(r"(\w+)=(\d+)")
print("\nExtract all key=value pairs:")
print(all_matches.head(6))


# ==============================================================================
# SECTION 8: RE MODULE FOR COMPLEX PATTERNS
# ==============================================================================

# The re module is useful when you need lookaheads, named groups across rows,
# or operations that the str accessor doesn't support cleanly.

def extract_year(text):
    """Return the first 4-digit year found in a string, or None."""
    if pd.isna(text):
        return np.nan
    m = re.search(r"\b(19|20)\d{2}\b", text)
    return int(m.group()) if m else np.nan

sample_texts = pd.Series([
    "Survey conducted in November 2020",
    "Data collection: 2019–2020",
    "No year here",
    np.nan
])

years_found = sample_texts.apply(extract_year)
print("\nYear extraction with re.search:")
print(pd.DataFrame({"text": sample_texts, "year": years_found}).to_string(index=False))

# re.sub() equivalent for a scalar string
raw = "  CES  2020   Common   Content  "
clean = re.sub(r"\s+", " ", raw).strip()
print(f"\nre.sub collapse whitespace: '{clean}'")


# ==============================================================================
# SECTION 9: COUNTING CHARACTERS AND WORDS
# ==============================================================================

# Character length
ces["name_len"] = ces["full_name"].str.len()

# Count occurrences of a substring
text_sample = pd.Series([
    "strongly agree",
    "agree",
    "neither agree nor disagree",
    "disagree",
    "strongly disagree"
])

word_counts = text_sample.str.split().str.len()
agree_count = text_sample.str.count("agree")

print("\nWord/occurrence counts:")
print(pd.DataFrame({
    "text": text_sample,
    "n_words": word_counts,
    "n_agree": agree_count
}).to_string(index=False))


# ==============================================================================
# SECTION 10: STANDARDIZING MERGE KEYS
# ==============================================================================

# Real-world scenario: merge CES with an external state-level file where
# state names are inconsistently formatted.

ces_states = ces[["caseid", "state_fips"]].copy()

# Simulate a state file with messy names
state_info = pd.DataFrame({
    "state_name": [" Florida", "georgia", "TEXAS", "New York ", "California"],
    "state_fips": [12, 13, 48, 36, 6],
    "region_label": ["South", "South", "South", "Northeast", "West"]
})

# Standardize keys before merge
state_info["state_key"] = (
    state_info["state_name"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", "_", regex=True)
)

print("\nStandardized state keys:")
print(state_info[["state_name","state_key","region_label"]].to_string(index=False))

# Merge on numeric FIPS (the safe approach when you have it)
ces_merged = ces_states.merge(
    state_info[["state_fips","region_label","state_key"]],
    on="state_fips",
    how="left"
)

print(f"\nMerge complete: {ces_merged['region_label'].notna().sum():,} matched rows")
print(ces_merged[["caseid","state_fips","region_label","state_key"]].head(8).to_string(index=False))


# ==============================================================================
# SECTION 11: BUILDING FIPS AND GEO CODES FROM PARTS
# ==============================================================================

# Construct a 5-digit county FIPS by zero-padding state (2) + county (3)
# Simulate county codes for demonstration
rng = np.random.default_rng(20240101)
ces["county_fips_raw"] = rng.integers(1, 999, size=len(ces))

state_str  = ces["state_fips"].astype(str).str.zfill(2)
county_str = ces["county_fips_raw"].astype(str).str.zfill(3)
ces["fips5"] = state_str + county_str

print("\nFIPS-5 construction (first 5):")
print(ces[["state_fips","county_fips_raw","fips5"]].head().to_string(index=False))


# ==============================================================================
# SECTION 12: ENCODING AND DECODING CATEGORICALS
# ==============================================================================

# pd.Categorical for memory-efficient storage of string variables
ces["race_cat"] = pd.Categorical(ces["race_title"].fillna("Unknown"))

print("\nRace categories:")
print(ces["race_cat"].value_counts())

# Map numeric codes back to labels for display
party_labels = {1: "Democrat", 2: "Republican", 3: "Independent"}
ces["party_label"] = ces["party_id3"].map(party_labels)

sex_labels = {1: "Male", 2: "Female"}
ces["sex_label"] = ces["sex"].map(sex_labels)

print("\nParty label distribution:")
print(ces["party_label"].value_counts(dropna=False))


# ==============================================================================
# SECTION 13: CLEANUP AND SAVE
# ==============================================================================

drop_cols = [
    "race_label", "race_lower", "race_upper", "race_title",
    "race_first3", "race_word1", "is_hispanic", "starts_w",
    "ends_ic", "is_mixed", "race_clean", "race_sentence",
    "full_name", "name_len", "interview_date", "geo_id",
    "county_fips_raw", "fips5", "race_cat", "party_label", "sex_label"
]

ces = ces.drop(columns=[c for c in drop_cols if c in ces.columns])

ces.to_parquet("CES2020_clean.parquet", index=False)
print("\nModule 13 complete.")
