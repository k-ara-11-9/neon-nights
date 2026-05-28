# --- 03_advanced_modeling.R ---
# Purpose: Enterprise Predictive Modeling, Causal Inference, and Economic Analysis
# Outputs: ML models (Random Forest, Decision Trees), Regression stats, and Visuals.

# Install packages if missing:
# install.packages(c("tidyverse", "randomForest", "rpart", "rpart.plot", "scales", "broom"))
library(tidyverse)
library(randomForest)
library(rpart)
library(rpart.plot)
library(scales)
library(broom)

cat("=========================================\n")
cat("  STARTING ADVANCED MODELING PIPELINE    \n")
cat("=========================================\n\n")

# 1. ENVIRONMENT SETUP
cat("[1/4] Configuring environment & loading data...\n")
if (!dir.exists("plots"))   dir.create("plots")
if (!dir.exists("outputs")) dir.create("outputs")

# Load pristine master dataset and explicitly type columns for Machine Learning
df <- read_csv("FINAL.csv", show_col_types = FALSE) %>%
  mutate(
    LocationName         = as.factor(LocationName),
    WeekDay              = as.factor(WeekDay),
    Season               = as.factor(Season),
    NightPeriod          = as.factor(NightPeriod),
    IsWeekend            = as.factor(IsWeekend),
    live_event_happening = as.factor(live_event_happening),
    uber_surge_active    = as.factor(uber_surge_active)
  )

# 2. MACRO-ECONOMIC ANALYSIS (The Multiplier Effect)
cat("[2/4] Calculating GDP Multiplier & Economic Impact...\n")

total_revenue <- sum(df$estimated_revenue_gbp, na.rm = TRUE)
total_gdp     <- sum(df$market_gdp_contribution_gbp, na.rm = TRUE)
multiplier    <- total_gdp / total_revenue

econ_df <- data.frame(
  Metric = c("Direct Venue Revenue", "Total GDP Contribution"),
  Value  = c(total_revenue, total_gdp)
)

p_econ <- ggplot(econ_df, aes(x = Metric, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", width = 0.6, color = "white", linewidth = 1) +
  scale_fill_manual(values = c("Direct Venue Revenue"  = "#E67E22",
                               "Total GDP Contribution" = "#27AE60")) +
  scale_y_continuous(labels = label_number(prefix = "£", suffix = " M", scale = 1e-6)) +
  geom_text(aes(label = paste0("£", round(Value / 1e6, 1), "M")),
            vjust = -0.5, fontface = "bold", size = 5) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold")) +
  labs(
    title    = paste("The Night Economy Multiplier Effect (Factor:", round(multiplier, 2), "x)"),
    subtitle = "Comparing direct till takings against broader local economic GDP contribution.",
    x        = "",
    y        = "Total Economic Value (Millions GBP)"
  ) +
  annotate("text", x = 1.5, y = total_gdp * 0.85,
           label = paste("+", round((multiplier - 1) * 100),
                         "% Indirect Impact\n(Taxis, Food, Wages)"),
           color = "#2C3E50", fontface = "italic", size = 5)

ggsave("plots/04_economic_multiplier_effect.png",
       plot = p_econ, width = 10, height = 6, dpi = 300)
cat("      -> Multiplier calculated at", round(multiplier, 2), "x. Plot saved.\n")

# 3. PREDICTIVE MODELING (Random Forest)
cat("[3/4] Training Random Forest Algorithm (Predicting Footfall)...\n")

# Downsample to 20,000 rows for memory-efficient training
set.seed(42)
rf_data <- df %>%
  select(TotalCount, LocationName, Hour, Season,
         IsWeekend, live_event_happening, hospitality_inflation_index) %>%
  drop_na() %>%
  sample_n(20000)

rf_model <- randomForest(TotalCount ~ .,
                         data      = rf_data,
                         ntree     = 100,
                         importance = TRUE)

imp_df <- as.data.frame(importance(rf_model)) %>%
  rownames_to_column("Feature") %>%
  arrange(desc(`%IncMSE`))

p_rf <- ggplot(imp_df,
               aes(x = reorder(Feature, `%IncMSE`),
                   y = `%IncMSE`, fill = `%IncMSE`)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  scale_fill_gradient(low = "#95A5A6", high = "#2980B9") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold")) +
  labs(
    title    = "AI Feature Importance (Random Forest)",
    subtitle = "Which variables are most critical for predicting a crowd?",
    x        = "Predictive Feature",
    y        = "Importance Score (Mean Decrease Accuracy)"
  )

ggsave("plots/05_random_forest_importance.png",
       plot = p_rf, width = 10, height = 6, dpi = 300)
cat("      -> Random Forest trained on 20,000 row sample. Plot saved.\n")

# 4. EXPLAINABLE AI (Visual Decision Tree)
cat("[4/4] Generating Explainable AI (XAI) Decision Tree...\n")

surge_thresh <- quantile(df$TotalCount, 0.90, na.rm = TRUE)

tree_data <- df %>%
  mutate(TrafficLevel = as.factor(
    ifelse(TotalCount >= surge_thresh, "Surge", "Normal")
  )) %>%
  select(TrafficLevel, LocationName, Hour, IsWeekend,
         live_event_happening, Season)

dt_model <- rpart(TrafficLevel ~ .,
                  data    = tree_data,
                  method  = "class",
                  control = rpart.control(cp = 0.005))

png("plots/06_xai_decision_tree.png", width = 1200, height = 900, res = 150)
rpart.plot(dt_model,
           main        = "Explainable AI: Predicting Nightlife Surge Events",
           extra       = 104,
           box.palette = c("#2ECC71", "#E74C3C"),
           shadow.col  = "gray",
           nn          = TRUE)
dev.off()

# 5. CAUSAL INFERENCE (Linear Regression Export)
lm_model  <- lm(market_gdp_contribution_gbp ~
                  TotalCount + hospitality_inflation_index + live_event_happening,
                data = df)

# Coefficient-level output (estimates, std errors, t-stats, p-values)
lm_results <- tidy(lm_model) %>%
  mutate(
    across(c(estimate, std.error, statistic), ~round(., 4)),
    p.value = format(p.value, scientific = TRUE, digits = 3)
  )

write_csv(lm_results, "outputs/02_linear_regression_gdp_impact.csv")
cat("      -> Coefficient table exported to 'outputs/'.\n")

# Model-level fit statistics (R-squared, adjusted R-squared, F-statistic)
lm_fit <- glance(lm_model) %>%
  mutate(across(where(is.numeric), ~round(., 4)))

write_csv(lm_fit, "outputs/03_linear_regression_model_fit.csv")
cat("      -> Model fit statistics (R-squared) exported to 'outputs/'.\n")

cat("\n=========================================\n")
cat("  PIPELINE COMPLETE! ALL ASSETS GENERATED\n")
cat("=========================================\n")