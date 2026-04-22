# App Store Success Analysis

An end-to-end R data science project that cleans Google Play Store data, engineers features, and answers 15 research questions about what drives app install success — using statistical tests, regression models, and logistic classification.

## Project Overview

This project investigates what makes a Google Play Store app successful. Using app metadata (installs, ratings, pricing, size, category, last update date) and user review sentiment, it answers 15 questions through descriptive analysis, hypothesis testing, regression modelling, and binary classification.

Key techniques used:
- Data cleaning and deduplication
- Sentiment polarity aggregation from user reviews
- Log-transformation of skewed install counts
- One-way ANOVA, t-tests, chi-square tests
- Simple and multiple linear regression
- Binary logistic regression (success classification)
- Feature engineering (`log_installs`, `log_reviews`, `high_success`, `is_free`, `days_since_update`)

## Research Questions Answered

| # | Question | Method |
|---|----------|--------|
| Q1 | How do install distributions vary across app categories? | Boxplot / summary statistics |
| Q2 | Which categories have the highest average installs? | Ranked bar chart |
| Q3 | Which categories consistently achieve significantly higher installs? | One-way ANOVA |
| Q4 | How do install patterns differ between Free and Paid apps? | Welch two-sample t-test |
| Q5 | Does price significantly impact installs after controlling for rating and category? | Multiple linear regression |
| Q6 | What is the correlation between user ratings and install levels? | Pearson correlation test |
| Q7 | Does review count independently influence install performance? | Multiple linear regression |
| Q8 | Is there a rating threshold above which install probability increases significantly? | Logistic regression + binned success rates |
| Q9 | Are Free apps statistically more likely to achieve 1M+ installs than Paid apps? | Chi-square test |
| Q10 | Is there an optimal price range for paid apps that maximises installs? | Price-bin aggregation |
| Q11 | Does app size significantly influence install performance? | Pearson correlation + simple linear regression |
| Q12 | Do recently updated apps outperform older apps in installs? | Simple linear regression |
| Q13 | Which categories have the highest success rate (≥1M installs)? | Category-level aggregation |
| Q14 | Which features best predict install volume? | Full multiple linear regression |
| Q15 | Can we classify app success with logistic regression? | Binary logistic regression + confusion matrix |

### Key Findings

- **Free apps** receive dramatically more installs than paid apps (mean log-installs: 11.58 vs 8.08; p < 2.2e-16).
- **Category** significantly affects installs (ANOVA F = 24.73, p < 2e-16). Entertainment, Game, and Education categories lead; Medical and Business categories lag.
- **Review count** is a strong independent predictor of installs even after controlling for rating and category.
- **Rating** has a statistically significant but weak positive correlation with installs (r = 0.06).
- **App size** has no meaningful impact on install performance (r ≈ −0.01, p = 0.40).
- **Update recency** matters: more days since the last update is associated with fewer installs (β = −0.0016, p < 2e-16).
- The **logistic classifier** (Q15) predicts 1M+ install success using category, rating, reviews, price, size, sentiment, and update recency.

## Repository Structure

```
AppStoreSuccess/
├── data/
│   ├── raw/                          # Raw Kaggle datasets (not included in repo)
│   └── cleaned/                      # Intermediate cleaned CSVs produced by scripts
├── preprocessing/
│   ├── cleaning.R                    # Cleans app & review data; writes apps_cleaned.csv,
│   │                                 #   review_summary.csv, and final_data.csv
│   └── analysis.R                    # Filters rows with missing Success; writes final_data_filtered.csv
├── outputs/
│   ├── Q1_summary.csv … Q15_metrics.txt   # Per-question CSV/TXT result files
│   └── plots/                        # PNG plots for Q1–Q15
├── merged_appstore_analysis_15_questions.R  # ★ Main integrated pipeline (all 15 questions)
├── 01_preprocessing.R                # Standalone preprocessing variant
├── 02_statistical_analysis.Rmd       # Detailed R Markdown report for Q1–Q12 (statistical analysis)
├── appstore.rmd                      # Full R Markdown document mirroring the pipeline
├── modelling.Rmd                     # R Markdown report focusing on ML modelling
├── appstore.html                     # Rendered HTML report (appstore.rmd)
├── modelling.html                    # Rendered HTML report (modelling.Rmd)
├── processed_appstore.csv            # Final analysis-ready dataset
└── README.md
```

## Data Sources

Original Kaggle datasets:

- **Apps**: <https://www.kaggle.com/datasets/lava18/google-play-store-apps>
- **Reviews**: <https://www.kaggle.com/datasets/prakharrathi25/google-play-store-reviews>

Expected raw files (place in `data/raw/`):

```
data/raw/googleplaystore.csv
data/raw/googleplaystore_user_reviews.csv
```

## Environment

R 4.x with the following packages:

```r
install.packages(c("dplyr", "readr", "stringr", "ggplot2", "rmarkdown"))
```

## How to Run

### Full integrated pipeline (recommended)

```bash
Rscript merged_appstore_analysis_15_questions.R
```

This single script:
1. Loads raw app and review data
2. Cleans and deduplicates records; converts installs, price, and size to numeric
3. Aggregates per-app review sentiment (average polarity + review count)
4. Merges apps with sentiment summary
5. Engineers features: `log_installs`, `log_reviews`, `is_free`, `high_success`, `days_since_update`
6. Answers Q1–Q15 with statistical tests, regression, and logistic classification
7. Exports all result CSVs/TXTs to `outputs/` and plots to `outputs/plots/`

### Step-by-step preprocessing (optional)

```bash
Rscript preprocessing/cleaning.R   # produces apps_cleaned.csv, review_summary.csv, final_data.csv
Rscript preprocessing/analysis.R   # produces final_data_filtered.csv
```

### Render R Markdown reports (optional)

```r
rmarkdown::render("02_statistical_analysis.Rmd")
rmarkdown::render("modelling.Rmd")
rmarkdown::render("appstore.rmd")
```

## Generated Outputs

### Cleaned / intermediate data

| File | Description |
|------|-------------|
| `data/cleaned/apps_cleaned.csv` | Deduplicated, type-converted app records |
| `data/cleaned/review_summary.csv` | Per-app average sentiment polarity and review count |
| `data/cleaned/final_data.csv` | Apps merged with sentiment; includes `Success` binary label |
| `data/cleaned/final_data_filtered.csv` | Rows with non-missing `Success` only |
| `processed_appstore.csv` | Final analysis-ready dataset with all engineered features |

### Analysis artifacts (`outputs/`)

| File | Content |
|------|---------|
| `Q1_summary.csv` | Mean log-installs per category |
| `Q2_top_categories.csv` | Top 10 categories by mean log-installs |
| `Q3_anova_summary.csv` | ANOVA table (log_installs ~ Category) |
| `Q4_type_means.csv` / `Q4_ttest.txt` | Free vs Paid means + t-test results |
| `Q5_model_price_summary.txt` | Linear regression: installs ~ price + rating + category |
| `Q6_correlation.txt` | Pearson correlation: rating vs log_installs |
| `Q7_model_reviews_summary.txt` | Linear regression: installs ~ reviews + rating + category |
| `Q8_rating_bin_success.csv` / `Q8_logit_summary.txt` | Rating-bin success rates + logistic regression |
| `Q9_type_high_success_counts.csv` / `Q9_chi_square.txt` | Chi-square test: Free/Paid × high_success |
| `Q10_price_bin_installs.csv` | Mean installs by price bin (paid apps only) |
| `Q11_correlation.txt` / `Q11_model_summary.txt` | Size vs installs correlation and regression |
| `Q12_model_summary.txt` | Regression: installs ~ days_since_update |
| `Q13_category_success.csv` | Success rate per category |
| `Q14_coefficients.csv` / `Q14_model_summary.txt` | Full linear model coefficients |
| `Q15_logit_model_summary.txt` / `Q15_confusion_matrix.txt` / `Q15_metrics.txt` | Logistic classifier results, confusion matrix, accuracy/precision/recall/F1 |

### Plots (`outputs/plots/`)

`Q1_installs_by_category_boxplot.png`, `Q2_top_categories_mean_installs.png`, `Q3_category_anova_context.png`, `Q4_free_vs_paid_installs.png`, `Q5_price_vs_installs.png`, `Q6_rating_vs_installs.png`, `Q7_reviews_vs_installs.png`, `Q8_rating_threshold_success.png`, `Q9_type_vs_high_success.png`, `Q10_paid_price_bin_installs.png`, `Q11_size_vs_installs.png`, `Q12_recency_vs_installs.png`, `Q13_top_category_success.png`, `Q14_linear_model_coefficients.png`, `Q15_logit_predicted_probabilities.png`

## Notes

- The canonical script for full reproduction is `merged_appstore_analysis_15_questions.R`. All other scripts and `.Rmd` files are supplementary or exploratory variants.
- `set.seed(42)` is used in `merged_appstore_analysis_15_questions.R` to ensure reproducibility of the Q15 train/test split.
- Output files in `outputs/` are generated artifacts and can be regenerated at any time by rerunning the main script.
