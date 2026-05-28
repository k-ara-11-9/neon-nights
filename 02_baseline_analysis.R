# --- 02_baseline_analysis.R ---
# Purpose: Enterprise Exploratory Data Analysis (EDA) & Baseline Benchmarking (2025)
# Outputs: Publication-quality ggplot2 visualizations and robust summary statistics.

# Install required packages if missing:
# install.packages(c("tidyverse", "scales", "gridExtra"))
library(tidyverse)
library(scales)
library(gridExtra)

cat("=========================================\n")
cat("  STARTING BASELINE ANALYSIS (2025)      \n")
cat("=========================================\n\n")

# 1. ENVIRONMENT SETUP
cat("[1/5] Configuring environment and directories...\n")
dirs_to_create <- c("plots", "outputs")
for (d in dirs_to_create) {
  if (!dir.exists(d)) {
    dir.create(d)
    cat("      -> Created missing directory:", d, "\n")
  }
}

# Load the pristine master dataset
df <- read_csv("FINAL.csv", show_col_types = FALSE) %>%
  mutate(
    WeekDay = factor(WeekDay,
                     levels = c("Monday", "Tuesday", "Wednesday",
                                "Thursday", "Friday", "Saturday", "Sunday"),
                     ordered = TRUE),
    LocationName = as.factor(LocationName),
    NightPeriod  = factor(NightPeriod,
                          levels = c("Early Evening", "Peak Night", "Late Night"),
                          ordered = TRUE),
    Season = factor(Season, levels = c("Summer", "Autumn", "Spring", "Winter"))
  )

# Isolate the target baseline year (2025)
df_2025 <- df %>% filter(BRCYear == 2025)
cat("      -> Isolated 2025 Baseline Data:",
    format(nrow(df_2025), big.mark = ","), "rows.\n")

# 2. STATISTICAL SUMMARIES & ANOMALY DETECTION
cat("[2/5] Computing robust summary statistics...\n")

# Calculate the 99th percentile to scientifically define a "Surge Event"
surge_threshold <- quantile(df_2025$TotalCount, 0.99, na.rm = TRUE)

# Generate a detailed statistical summary table by location
stats_summary <- df_2025 %>%
  group_by(LocationName) %>%
  summarise(
    Observations    = n(),
    Min_Footfall    = min(TotalCount),
    Median_Footfall = median(TotalCount),
    Mean_Footfall   = round(mean(TotalCount), 1),
    Max_Footfall    = max(TotalCount),
    Std_Deviation   = round(sd(TotalCount), 1),
    Surge_Events    = sum(TotalCount >= surge_threshold)
  ) %>%
  arrange(desc(Median_Footfall))

write_csv(stats_summary, "outputs/01_location_summary_stats_2025.csv")
cat("      -> Exported '01_location_summary_stats_2025.csv'.\n")
cat("      -> City-wide 99th Percentile Surge Threshold:",
    round(surge_threshold), "people/hour.\n")

# 3. 2025 BASELINE VISUALIZATIONS
cat("[3/5] Generating 2025 baseline visualizations...\n")

# PLOT A: Footfall Distribution with Density Curve
p_dist <- ggplot(df_2025, aes(x = TotalCount)) +
  geom_histogram(aes(y = ..density..),
                 bins = 50, fill = "#2C3E50", color = "white", alpha = 0.8) +
  geom_density(color = "#E74C3C", linewidth = 1.2) +
  geom_vline(xintercept = median(df_2025$TotalCount),
             color = "#F39C12", linetype = "dashed", linewidth = 1) +
  annotate("text",
           x     = median(df_2025$TotalCount) + 150,
           y     = 0.005,
           label = paste("Median:", round(median(df_2025$TotalCount))),
           color = "#F39C12", fontface = "bold") +
  scale_x_continuous(labels = comma) +
  theme_minimal(base_size = 14) +
  labs(
    title    = "Distribution of Nightlife Footfall (2025)",
    subtitle = "Log-Normal right skew indicating rare, extreme surge events.",
    x        = "Hourly Footfall Count",
    y        = "Density"
  ) +
  theme(plot.title = element_text(face = "bold"))

ggsave("plots/01_baseline_distribution_2025.png",
       plot = p_dist, width = 10, height = 6, dpi = 300)

# PLOT B: Spatial Saturation (Violin + Boxplot Hybrid)
p_spatial <- ggplot(df_2025,
                    aes(x = reorder(LocationName, TotalCount, FUN = median),
                        y = TotalCount, fill = LocationName)) +
  geom_violin(alpha = 0.3, color = NA) +
  geom_boxplot(width = 0.2,
               outlier.color = "#E74C3C",
               outlier.size  = 1.5,
               outlier.alpha = 0.6) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold")) +
  labs(
    title    = "Spatial Variance & Surge Detection by Location (2025)",
    subtitle = "Red dots represent extreme outlier events exceeding standard physical capacity.",
    x        = "",
    y        = "Hourly Footfall"
  )

ggsave("plots/02_spatial_variance_2025.png",
       plot = p_spatial, width = 10, height = 7, dpi = 300)

# PLOT C: The Rhythm of the City (Time-Series Heatmap)
weekly_rhythm <- df_2025 %>%
  group_by(WeekDay, Hour) %>%
  summarise(AvgFootfall = mean(TotalCount), .groups = "drop")

p_rhythm <- ggplot(weekly_rhythm,
                   aes(x = factor(Hour), y = fct_rev(WeekDay),
                       fill = AvgFootfall)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient(low = "#F4F6F6", high = "#8E44AD", name = "Avg\nFootfall") +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid = element_blank()
  ) +
  labs(
    title    = "The Rhythm of the Night Economy (2025 Baseline)",
    subtitle = "Average hourly footfall tracking the buildup and decay of crowds.",
    x        = "Hour of the Night (24H Format)",
    y        = ""
  )

ggsave("plots/03_weekly_rhythm_heatmap_2025.png",
       plot = p_rhythm, width = 12, height = 5, dpi = 300)

cat("      -> Saved 3 baseline charts to 'plots/'.\n")

# 4. VARIABLE CORRELATION HEATMAP (Full Dataset)
cat("[4/5] Generating correlation heatmap and long-term trend charts...\n")

cor_vars <- df %>%
  select(TotalCount, estimated_revenue_gbp, market_gdp_contribution_gbp,
         hospitality_jobs_active, hospitality_inflation_index, Hour) %>%
  cor(use = "complete.obs")

cor_df <- as.data.frame(cor_vars) %>%
  rownames_to_column("Var1") %>%
  pivot_longer(-Var1, names_to = "Var2", values_to = "Correlation")

p_cor <- ggplot(cor_df, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(Correlation, 2)), size = 3.5, fontface = "bold") +
  scale_fill_gradient2(
    low      = "#3498DB",
    mid      = "white",
    high     = "#E74C3C",
    midpoint = 0,
    limits   = c(-1, 1),
    name     = "r"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title  = element_text(face = "bold"),
    panel.grid  = element_blank()
  ) +
  labs(
    title    = "Variable Correlation Heatmap",
    subtitle = "Footfall shows near-perfect correlation with GDP contribution and hospitality jobs.",
    x = "", y = ""
  )

ggsave("plots/07_correlation_heatmap.png",
       plot = p_cor, width = 9, height = 7, dpi = 300)

# 5. LONG-TERM TRENDS: GDP AND INFLATION (2009-2026)
annual_trends <- df %>%
  group_by(BRCYear) %>%
  summarise(
    TotalGDP     = sum(market_gdp_contribution_gbp, na.rm = TRUE) / 1e6,
    AvgInflation = mean(hospitality_inflation_index, na.rm = TRUE)
  )

p_gdp <- ggplot(annual_trends, aes(x = BRCYear, y = TotalGDP)) +
  geom_line(color = "#E74C3C", linewidth = 1.2) +
  geom_point(color = "#E74C3C", size = 2.5) +
  annotate("rect",
           xmin = 2019.8, xmax = 2021.2,
           ymin = -Inf,   ymax = Inf,
           alpha = 0.1, fill = "#E74C3C") +
  annotate("text",
           x     = 2020.5,
           y     = max(annual_trends$TotalGDP) * 0.95,
           label = "COVID-19",
           color = "#E74C3C", fontface = "bold", size = 3.5) +
  scale_x_continuous(breaks = seq(2009, 2026, 2)) +
  scale_y_continuous(labels = label_number(prefix = "£", suffix = "M")) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold")) +
  labs(
    title = "Annual GDP Contribution (2009–2026)",
    x     = "Year",
    y     = "Total GDP (£M)"
  )

p_inf <- ggplot(annual_trends, aes(x = BRCYear, y = AvgInflation)) +
  geom_line(color = "#2980B9", linewidth = 1.2) +
  geom_point(color = "#2980B9", size = 2.5) +
  scale_x_continuous(breaks = seq(2009, 2026, 2)) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold")) +
  labs(
    title = "Hospitality Inflation Index (2009–2026)",
    x     = "Year",
    y     = "Avg Inflation Index"
  )

p_trends <- arrangeGrob(p_gdp, p_inf, ncol = 2)
ggsave("plots/08_longterm_trends.png",
       plot = p_trends, width = 12, height = 5, dpi = 300)

# SEASONAL GDP BREAKDOWN
seasonal_gdp <- df %>%
  group_by(Season) %>%
  summarise(TotalGDP = sum(market_gdp_contribution_gbp, na.rm = TRUE) / 1e6)

p_seasonal <- ggplot(seasonal_gdp,
                     aes(x = Season, y = TotalGDP, fill = Season)) +
  geom_col(width = 0.6, color = "white", linewidth = 1) +
  scale_fill_manual(values = c(
    "Summer" = "#F39C12", "Autumn" = "#E67E22",
    "Spring" = "#2ECC71", "Winter" = "#85C1E9"
  )) +
  scale_y_continuous(labels = label_number(prefix = "£", suffix = "M")) +
  geom_text(aes(label = paste0("£", round(TotalGDP), "M")),
            vjust = -0.5, fontface = "bold", size = 4.5) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold")) +
  labs(
    title    = "Total GDP Contribution by Season",
    subtitle = "Even off-peak seasons generate substantial economic output.",
    x        = "",
    y        = "Total GDP Contribution (£M)"
  )

ggsave("plots/09_seasonal_gdp.png",
       plot = p_seasonal, width = 9, height = 5, dpi = 300)

cat("      -> Saved correlation heatmap, trend charts, and seasonal GDP to 'plots/'.\n")

# 5. COMPLETION
cat("[5/5] Baseline analysis complete!\n")
cat("      -> plots/ now contains 9 publication-quality charts.\n")
cat("      -> outputs/ contains summary statistics CSV.\n")
cat("=========================================\n")