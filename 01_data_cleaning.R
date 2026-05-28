# --- 01_data_cleaning.R ---
# Purpose: Enterprise-grade Data Cleaning Pipeline
# Handles: Chronological sorting, deduplication, NA handling, type casting, and scope filtering.

# Install required packages if missing: install.packages(c("tidyverse", "lubridate"))
library(tidyverse)
library(lubridate)

cat("=========================================\n")
cat("  STARTING ETL DATA CLEANING PIPELINE    \n")
cat("=========================================\n\n")

# 1. INGESTION
cat("[1/5] Loading raw sensor data...\n")
raw_df <- read_csv("raw_footfall.csv", show_col_types = FALSE)
cat("      -> Initial rows loaded:", format(nrow(raw_df), big.mark = ","), "\n")

# 2. DATA TYPING & FORMATTING
cat("[2/5] Parsing timestamps and casting categorical features...\n")
typed_df <- raw_df %>%
  mutate(
    # Parse Dates strictly from DD/MM/YYYY HH:MM:SS
    Date = dmy_hms(Date),
    
    # Convert text to Ordered Factors (Crucial for Random Forest and plots)
    LocationName = as.factor(LocationName),
    WeekDay = factor(WeekDay, 
                     levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"), 
                     ordered = TRUE),
    Season = factor(Season, 
                    levels = c("Spring", "Summer", "Autumn", "Winter")),
    NightPeriod = as.factor(NightPeriod),
    BRCMonth = as.factor(BRCMonth)
  ) %>%
  # Drop the meaningless API-generated Id column
  select(-Id)

# 3. FIXING NETWORK & SENSOR ERRORS
cat("[3/5] Resolving network duplicates and sensor dropouts...\n")
clean_df <- typed_df %>%
  # A. Deduplication: Remove the 4% double-pings injected by the simulated API
  distinct() %>%
  
  # B. Chronological Sort: Fix the shuffled network latency to restore time-series integrity
  arrange(LocationName, Date) %>%
  
  # C. Sensor Outages: Remove rows where the battery died (NA TotalCount)
  filter(!is.na(TotalCount))

cat("      -> Rows after error correction:", format(nrow(clean_df), big.mark = ","), "\n")

# 4. SCOPE FILTERING (ISOLATING NIGHT ECONOMY)
cat("[4/5] Filtering for Night Economy scope (6 PM - 6 AM)...\n")
night_economy_df <- clean_df %>%
  filter(Hour >= 18 | Hour < 6)

cat("      -> Final Night Economy rows:", format(nrow(night_economy_df), big.mark = ","), "\n")

# 5. DATASET EXPORT
cat("[5/5] Exporting pristine master dataset...\n")
# write_csv is faster than write.csv and prevents rownames from being added
write_csv(night_economy_df, "FINAL.csv")

cat("      -> SUCCESS: 'FINAL.csv' generated and ready for analysis.\n")
cat("\n=========================================\n")