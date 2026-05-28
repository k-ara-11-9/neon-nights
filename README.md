# Neon Nights — UK Night Economy Analysis

**Team:** Midnight Explorers  
**Members:** Saranya Ghosh · Dristi Sengupta · Shruti Singha · Sneha Bhowmick

---

## Overview

This project investigates the macroeconomic value of the UK's **Night Economy** — asking how global factors such as inflation, seasonality, and pandemics threaten this critical engine of national development.

Using real-world pedestrian footfall data from York's nightlife districts (2009–2026), we quantify the relationship between nighttime activity and GDP, hospitality employment, and economic resilience.

**Scope:** Urban planning and economic policy within the UK nightlife sector.

---

## The Core Question

> *What is the true macroeconomic value of the 'Night Economy,' and how do global factors (inflation, seasonality, pandemics) threaten this critical engine of national development?*

---

## Key Findings

| Finding | Detail |
|---|---|
| Near-perfect footfall–GDP correlation | r = 0.95 (Market GDP), r = 0.96 (Hospitality Jobs) |
| The 1.45× Multiplier | Every £1 of direct nightlife revenue generates £0.45 in additional indirect/induced economic impact |
| Seasonal Strength | Summer peaks at ~£400M GDP; even winter contributes ~£300M |
| Pandemic Vulnerability | GDP collapsed in 2020, demonstrating acute sensitivity to external shocks |
| Inflation Threat | ~50% rise in the Hospitality Inflation Index (2009–2026) correlates with recent GDP decline |
| Location Inequality | Coney Street (15.97M footfall) dominates vs. Church Street (1.14M) |

---

## Dataset

The dataset is hosted publicly on Kaggle and must be downloaded separately before running the pipeline.

**[Download Dataset → Kaggle](https://www.kaggle.com/datasets/dristi53/night-tourism-uk-footfall-dataset)**

After downloading, place the file as `raw_footfall.csv` in the project root directory.

> The dataset covers hourly pedestrian footfall across 9 key nightlife locations in York, UK, from 2009 to 2026, enriched with economic indicators (GDP contribution, hospitality inflation, live events, Uber surge, police visibility, etc.).

---

## Project Structure

```
neon_nights/
│
├── 01_data_cleaning.R          # ETL pipeline: deduplication, type casting, scope filter (6 PM–6 AM)
├── 02_baseline_analysis.R      # EDA: correlation heatmap, seasonal GDP, location stats
├── 03_advanced_modeling.R      # Predictive modeling: Random Forest, regression, multiplier effect
├── generate_raw_data.py        # Synthetic data generator used to build the Kaggle dataset
├── Report.Rmd                  # Full R Markdown report (renders to Report.html)
├── neon_nights.Rproj           # RStudio project file
│
├── plots/                      # Generated plots (gitignored)
└── outputs/                    # Generated CSV summaries (gitignored)
```

---

## Setup & Usage

### Prerequisites

- **R** ≥ 4.2.0 and **RStudio**
- **Python** ≥ 3.9 (only needed to re-run `generate_raw_data.py`)

### Step 1 — Install R Packages

Run the following once in your R console, or source `install_packages.R`:

```r
install.packages(c(
  "tidyverse",
  "lubridate",
  "scales",
  "gridExtra",
  "randomForest",
  "rpart",
  "rpart.plot",
  "broom"
))
```

### Step 2 — Download the Dataset

Download `raw_footfall.csv` from the [Kaggle dataset page](https://www.kaggle.com/datasets/dristi53/night-tourism-uk-footfall-dataset) and place it in the project root.

### Step 3 — Run the Pipeline

Execute the R scripts in order from the RStudio console or terminal:

```r
source("01_data_cleaning.R")      # Produces FINAL.csv
source("02_baseline_analysis.R")  # Produces plots/ and outputs/
source("03_advanced_modeling.R")  # Produces advanced model plots and outputs/
```

### Step 4 — Render the Report

```r
rmarkdown::render("Report.Rmd")   # Produces Report.html
```

### Python (Optional)

Only needed if you want to regenerate the raw dataset from scratch:

```bash
pip install -r requirements.txt
python generate_raw_data.py
```

---

## Analysis Pipeline

```
raw_footfall.csv
      │
      ▼
01_data_cleaning.R  ──────────►  FINAL.csv  (filtered to 6 PM–6 AM nighttime window)
                                      │
                    ┌─────────────────┴──────────────────┐
                    ▼                                     ▼
      02_baseline_analysis.R               03_advanced_modeling.R
      (EDA, heatmaps, seasonal GDP)        (Random Forest, regression,
                    │                       1.45× multiplier model)
                    └─────────────────┬──────────────────┘
                                      ▼
                                 Report.Rmd  ──►  Report.html
```

---

## Road Ahead

1. **Predictive Economic Modelling**  
   Extend existing regression (`lm()`) and Random Forest models into forecasting frameworks to analyze how rising Hospitality Inflation Index trends may influence future footfall patterns and potential employment impacts.

2. **Geospatial Hotspot Analysis**  
   Incorporate GIS-based mapping techniques to identify and visualize high-density footfall zones, and examine the relationship between localized economic activity (GDP) and diminishing returns in hyper-dense urban areas.

3. **Cost-of-the-Surge Analysis**  
   Build on current distributional insights to quantify the economic inefficiencies of average-based urban planning, using statistical analysis of right-skewed footfall data to capture underlying disparities.

---

## License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

The dataset is available on Kaggle under its own terms. Please cite appropriately if used in academic work.

---

## Citation

If you use this project or dataset in academic work, please cite:

```
Midnight Explorers (Ghosh, Sengupta, Singha, Bhowmick). 
"Neon Nights: Macroeconomic Analysis of the UK Night Economy." 2026.
Dataset: https://www.kaggle.com/datasets/dristi53/night-tourism-uk-footfall-dataset
```
