# ==============================================================================
#  MODULE 13: STRING MANIPULATION WITH STRINGR
#  Dataset: CES 2020 (cleaned in Module 1) + simulated string variables
#
#  Purpose: Work with string data in R using stringr (part of tidyverse).
#  stringr functions are consistent: all take the string as the first argument
#  and all start with str_ — easy to remember and autocomplete.
#
#  Key stringr functions:
#    str_to_lower / str_to_upper / str_to_title  — case conversion
#    str_trim / str_squish                        — remove whitespace
#    str_length                                   — string length
#    str_sub                                      — extract substring
#    str_c / str_glue                             — concatenate strings
#    str_replace / str_replace_all                — find and replace
#    str_detect                                   — does string match pattern?
#    str_extract / str_extract_all                — extract matching substring
#    str_split                                    — split on delimiter
#    str_pad / str_trunc                          — pad or truncate
# ==============================================================================

library(tidyverse)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: CREATE EXAMPLE STRING VARIABLES
# ==============================================================================

# Simulate messy state names as you'd get from a messy CSV join
ces <- ces |>
  mutate(
    state_name = case_when(
      state_fips == 12 ~ "  Florida  ",
      state_fips == 13 ~ "GEORGIA",
      state_fips == 36 ~ "New York",
      state_fips == 48 ~ "texas",
      state_fips ==  6 ~ "California ",
      state_fips == 42 ~ "Pennsylvania",
      state_fips == 39 ~ "ohio",
      state_fips == 26 ~ "MICHIGAN",
      state_fips == 37 ~ " North Carolina",
      state_fips ==  4 ~ "Arizona",
      TRUE             ~ NA_character_
    )
  )

# Simulate an open-ended text field
ces <- ces |>
  mutate(
    econ_text = case_when(
      row_number() == 1 ~ "Things are getting worse every year",
      row_number() == 2 ~ "I feel pretty secure financially",
      row_number() == 3 ~ "very worried about job loss",
      row_number() == 4 ~ "stable but not great",
      TRUE              ~ NA_character_
    )
  )


# ==============================================================================
# SECTION 2: BASIC STRING FUNCTIONS
# ==============================================================================

# Case conversion
ces |>
  select(state_name) |>
  filter(!is.na(state_name)) |>
  mutate(
    lower  = str_to_lower(state_name),
    upper  = str_to_upper(state_name),
    title  = str_to_title(state_name)
  ) |>
  distinct() |>
  head(10)

# Trim whitespace
ces |>
  filter(!is.na(state_name)) |>
  mutate(
    state_trimmed = str_trim(state_name),        # removes leading + trailing spaces
    state_squish  = str_squish(state_name)       # also collapses internal spaces
  ) |>
  select(state_name, state_trimmed) |>
  distinct()

# String length (after trimming)
ces |>
  filter(!is.na(state_name)) |>
  mutate(len = str_length(str_trim(state_name))) |>
  count(len)

# Clean pipeline: trim + title case
ces <- ces |>
  mutate(
    state_clean = str_to_title(str_trim(state_name))
  )


# ==============================================================================
# SECTION 3: EXTRACTING SUBSTRINGS
# ==============================================================================

# str_sub(string, start, end) extracts characters at positions start through end
# Negative values count from the end of the string

ces |>
  filter(!is.na(state_clean)) |>
  mutate(
    first5   = str_sub(state_clean, 1, 5),
    last5    = str_sub(state_clean, -5, -1),
    char3    = str_sub(state_clean, 3, 3)    # just the third character
  ) |>
  select(state_clean, first5, last5) |>
  distinct()

# Detect whether state name contains "New"
ces |>
  filter(!is.na(state_clean)) |>
  mutate(has_new = str_detect(state_clean, "New")) |>
  count(has_new)


# ==============================================================================
# SECTION 4: FIND AND REPLACE
# ==============================================================================

# str_replace(string, pattern, replacement) — replaces first match
# str_replace_all() — replaces all matches

ces |>
  filter(!is.na(state_clean)) |>
  mutate(
    # Remove all spaces
    no_spaces = str_replace_all(state_clean, " ", ""),
    # Standardize abbreviation
    fixed = str_replace(state_clean, "N\\. Carolina", "North Carolina")
  ) |>
  select(state_clean, no_spaces, fixed) |>
  distinct()


# ==============================================================================
# SECTION 5: REGULAR EXPRESSIONS
# ==============================================================================

# R uses PCRE regular expressions. The same special characters apply:
#   \\d   = digit (note double backslash in R strings)
#   \\s   = whitespace
#   \\w   = word character (letter, digit, underscore)
#   [0-9] = any digit
#   [A-Z] = any uppercase letter
#   ^     = start of string
#   $     = end of string
#   ()    = capture group (accessed via str_match or backreferences)
#   |     = OR

# Does state name contain any digit?
ces |>
  filter(!is.na(state_name)) |>
  mutate(has_digit = str_detect(state_name, "[0-9]")) |>
  filter(has_digit) |>
  nrow()   # should be 0

# Detect whether econ_text mentions job-related terms
ces |>
  filter(!is.na(econ_text)) |>
  mutate(
    mentions_job     = str_detect(str_to_lower(econ_text), "job|work|employ"),
    mentions_decline = str_detect(str_to_lower(econ_text), "worse|worried|loss|decline|bad")
  ) |>
  select(econ_text, mentions_job, mentions_decline)

# Extract 4-digit year from a date string
dates <- c("10/01/2020", "2020-10-02", "Oct 03, 2020", "10-04-2020")
str_extract(dates, "\\d{4}")   # extract first 4-digit sequence

# Extract month from "10/01/2020" format
str_match("10/01/2020", "(\\d{2})/(\\d{2})/(\\d{4})")
# Column 2 = month, column 3 = day, column 4 = year

# Validate email format
emails <- c("user@domain.com", "bademail", "user@.com", "good@uni.edu")
str_detect(emails, "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")


# ==============================================================================
# SECTION 6: SPLITTING STRINGS
# ==============================================================================

# str_split() returns a list (one element per input string)
# Use tidyr::separate() for splitting inside a dataframe — much more convenient

# Simulate a survey date variable
dates_df <- tibble(
  id   = 1:4,
  date_str = c("10/01/2020", "10/02/2020", "10/03/2020", "10/04/2020")
)

# separate() splits on a delimiter into multiple columns
dates_df |>
  separate(date_str, into = c("month", "day", "year"),
           sep = "/", convert = TRUE)

# Simulate a name variable (Last, First format)
names_df <- tibble(
  id   = 1:4,
  name = c("Smith, John A.", "jones, mary", "BROWN, JAMES", "Williams, Sue")
)

names_df |>
  separate(name, into = c("last_name", "first_name"),
           sep = ",", extra = "drop") |>
  mutate(
    last_name  = str_to_title(str_trim(last_name)),
    first_name = str_to_title(str_trim(first_name))
  )

# str_split_fixed() returns a matrix instead of a list — easier for two-part splits
str_split_fixed(names_df$name, ",", n = 2)


# ==============================================================================
# SECTION 7: COMBINING STRINGS
# ==============================================================================

# str_c() is the tidyverse equivalent of paste0() — concatenates strings
# str_glue() is even more readable: embed variables with {var}

ces |>
  filter(!is.na(state_fips)) |>
  mutate(
    # Zero-pad state FIPS to 2 digits, county to 3 digits
    state_fips_padded  = str_pad(state_fips, width = 2, pad = "0"),
    county_fips_fake   = sample(1:900, nrow(ces), replace = TRUE),
    county_fips_padded = str_pad(county_fips_fake, width = 3, pad = "0"),
    full_fips          = str_c(state_fips_padded, county_fips_padded)
  ) |>
  select(state_fips, state_fips_padded, county_fips_padded, full_fips) |>
  head(5)

# str_glue() for readable string interpolation
respondent_id <- 12345
wave          <- "post"
str_glue("Respondent {respondent_id} — wave: {wave}")


# ==============================================================================
# SECTION 8: STRING OPERATIONS ON MERGE KEYS
# ==============================================================================

# When merging on string keys, standardize both sides first:
# 1. str_trim()       — remove whitespace
# 2. str_to_lower()   — consistent case
# 3. str_squish()     — collapse internal spaces

# Simulate a lookup table
state_lookup <- tibble(
  state_key = c("florida", "georgia", "new york", "texas",
                "california", "pennsylvania", "ohio", "michigan",
                "north carolina", "arizona"),
  state_abbrev = c("FL","GA","NY","TX","CA","PA","OH","MI","NC","AZ")
)

ces_keyed <- ces |>
  filter(!is.na(state_name)) |>
  mutate(
    state_key = str_to_lower(str_squish(str_trim(state_name)))
  )

ces_with_abbrev <- ces_keyed |>
  left_join(state_lookup, by = "state_key")

ces_with_abbrev |>
  filter(!is.na(state_name)) |>
  count(state_abbrev, sort = TRUE)


# ==============================================================================
# SECTION 9: WORD COUNTS AND TEXT FEATURES
# ==============================================================================

# Count words using str_count with a word-boundary pattern
ces |>
  filter(!is.na(econ_text)) |>
  mutate(word_count = str_count(econ_text, "\\S+")) |>  # \\S+ = non-whitespace runs
  select(econ_text, word_count)

# Extract all words
ces |>
  filter(!is.na(econ_text)) |>
  mutate(words = str_extract_all(str_to_lower(econ_text), "\\w+")) |>
  select(econ_text, words) |>
  head(4)

# Frequency of specific terms
ces |>
  filter(!is.na(econ_text)) |>
  summarise(
    n_mentions_job     = sum(str_detect(str_to_lower(econ_text), "job|work")),
    n_mentions_decline = sum(str_detect(str_to_lower(econ_text), "worse|worried|loss"))
  )


# ==============================================================================
# SECTION 10: CLEANUP
# ==============================================================================

ces <- ces |>
  select(-state_name, -state_clean, -econ_text)

saveRDS(ces, "CES2020_clean.rds")
message("Module 13 complete.")
