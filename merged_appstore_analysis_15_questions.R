

suppressPackageStartupMessages({
	library(dplyr)
	library(readr)
	library(stringr)
	library(ggplot2)
})

set.seed(42)

# -----------------------------
# Paths
# -----------------------------
raw_apps_path <- "data/raw/googleplaystore.csv"
raw_reviews_path <- "data/raw/googleplaystore_user_reviews.csv"

clean_apps_path <- "data/cleaned/apps_cleaned.csv"
review_summary_path <- "data/cleaned/review_summary.csv"
final_data_path <- "data/cleaned/final_data.csv"
final_filtered_path <- "data/cleaned/final_data_filtered.csv"
processed_path <- "processed_appstore.csv"

output_dir <- "outputs"
plot_dir <- file.path(output_dir, "plots")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)

# -----------------------------
# 1) Load raw data
# -----------------------------
apps <- read_csv(raw_apps_path, show_col_types = FALSE)
reviews <- read_csv(raw_reviews_path, show_col_types = FALSE)

# -----------------------------
# 2) Clean apps data (deduplicated)
# -----------------------------
apps_clean <- apps %>%
	filter(!is.na(Category), !is.na(Rating)) %>%
	distinct(App, .keep_all = TRUE) %>%
	mutate(
		Reviews = as.numeric(Reviews),
		Installs = as.numeric(str_replace_all(str_replace_all(Installs, "\\+", ""), ",", "")),
		Price = as.numeric(str_replace(Price, "\\$", "")),
		# Handle mixed size formats before numeric conversion
		Size = ifelse(Size == "Varies with device", NA, Size),
		Size = str_replace(Size, "k", ""),
		Size = str_replace(Size, "M", ""),
		Size = as.numeric(Size)
	)

apps_clean <- apps_clean %>%
	mutate(
		Category = as.factor(Category),
		Type = as.factor(Type),
		`Content Rating` = as.factor(`Content Rating`),
		Genres = as.factor(Genres)
	)

write_csv(apps_clean, clean_apps_path)

# -----------------------------
# 3) Clean reviews + summarize sentiment
# -----------------------------
reviews_clean <- reviews %>%
	filter(!is.na(Translated_Review)) %>%
	select(App, Sentiment_Polarity)

reviews_clean$Sentiment_Polarity[is.na(reviews_clean$Sentiment_Polarity)] <- 0

review_summary <- reviews_clean %>%
	group_by(App) %>%
	summarise(
		Avg_Sentiment = mean(Sentiment_Polarity, na.rm = TRUE),
		Review_Count = n(),
		.groups = "drop"
	)

write_csv(review_summary, review_summary_path)

# -----------------------------
# 4) Merge apps + review summary
# -----------------------------
final_data <- apps_clean %>%
	left_join(review_summary, by = "App") %>%
	mutate(
		Avg_Sentiment = ifelse(is.na(Avg_Sentiment), 0, Avg_Sentiment),
		Review_Count = ifelse(is.na(Review_Count), 0, Review_Count),
		Success = ifelse(Installs >= 1000000, 1, 0),
		Success = as.factor(Success)
	)

write_csv(final_data, final_data_path)

final_data_filtered <- final_data %>% filter(!is.na(Success))
write_csv(final_data_filtered, final_filtered_path)

# -----------------------------
# 5) Build processed dataset for statistical + ML analysis
# -----------------------------
df <- final_data

df <- df %>%
	mutate(
		Installs = as.numeric(Installs),
		Reviews = as.numeric(Reviews),
		Rating = as.numeric(Rating),
		Price = as.numeric(Price),
		Size = as.numeric(Size),
		log_installs = log1p(Installs),
		log_reviews = log1p(Reviews),
		is_free = ifelse(Type == "Free", 1, 0),
		high_success = ifelse(Installs >= 1000000, 1, 0),
		Last_Updated = as.Date(`Last Updated`, format = "%B %d, %Y"),
		days_since_update = as.numeric(Sys.Date() - Last_Updated)
	)

if ("Genres" %in% names(df)) {
	df$Genres <- NULL
}

# Keep naming compatibility used in your different files
names(df)[names(df) == "Content Rating"] <- "Content.Rating"

df <- df %>%
	mutate(
		Category = as.factor(Category),
		Type = as.factor(Type),
		Content.Rating = as.factor(Content.Rating)
	) %>%
	na.omit()

write.csv(df, processed_path, row.names = FALSE)

cat("Merged preprocessing completed. Rows in final analysis dataset:", nrow(df), "\n")

# -----------------------------
# Plot helper
# -----------------------------
save_plot <- function(plot_obj, filename, width = 10, height = 6) {
	ggsave(filename = file.path(plot_dir, filename), plot = plot_obj, width = width, height = height)
}

base_plot <- theme_minimal(base_size = 12) +
	theme(
		plot.title = element_text(face = "bold"),
		panel.grid.minor = element_blank()
	)

# -----------------------------
# 15 QUESTIONS: ANSWERS + GRAPHS (CODE ONLY)
# -----------------------------

# Q1: Install distribution across categories
q1_summary <- df %>% group_by(Category) %>% summarise(mean_log_installs = mean(log_installs), .groups = "drop")

p1 <- ggplot(df, aes(x = reorder(Category, log_installs, FUN = median), y = log_installs)) +
	geom_boxplot(fill = "#4C78A8", alpha = 0.75) +
	coord_flip() +
	labs(title = "Q1: Install Distribution Across Categories", x = "Category", y = "Log(Installs)") +
	base_plot
save_plot(p1, "Q1_installs_by_category_boxplot.png")

# Q2: Top categories by average installs
q2_top_categories <- q1_summary %>% arrange(desc(mean_log_installs)) %>% slice_head(n = 10)

p2 <- ggplot(q2_top_categories, aes(x = reorder(Category, mean_log_installs), y = mean_log_installs)) +
	geom_col(fill = "#F58518", alpha = 0.85) +
	coord_flip() +
	labs(title = "Q2: Top 10 Categories by Mean Log Installs", x = "Category", y = "Mean Log(Installs)") +
	base_plot
save_plot(p2, "Q2_top_categories_mean_installs.png")

# Q3: Which categories differ significantly in installs? (ANOVA)
q3_anova <- aov(log_installs ~ Category, data = df)
q3_anova_summary <- summary(q3_anova)

p3 <- ggplot(df, aes(x = Category, y = log_installs)) +
	geom_violin(fill = "#54A24B", alpha = 0.6) +
	geom_boxplot(width = 0.1, outlier.alpha = 0.2) +
	coord_flip() +
	labs(title = "Q3: Category-wise Install Variation (ANOVA context)", x = "Category", y = "Log(Installs)") +
	base_plot
save_plot(p3, "Q3_category_anova_context.png")

# Q4: Free vs Paid install difference
q4_type_means <- aggregate(log_installs ~ Type, data = df, mean)
q4_ttest <- t.test(log_installs ~ Type, data = df)

p4 <- ggplot(df, aes(x = Type, y = log_installs, fill = Type)) +
	geom_boxplot(alpha = 0.75) +
	scale_fill_manual(values = c("Free" = "#72B7B2", "Paid" = "#E45756")) +
	labs(title = "Q4: Free vs Paid Install Patterns", x = "Type", y = "Log(Installs)") +
	base_plot +
	theme(legend.position = "none")
save_plot(p4, "Q4_free_vs_paid_installs.png")

# Q5: Does price impact installs after controlling for rating and category?
q5_model_price <- lm(log_installs ~ Price + Rating + Category, data = df)
q5_model_price_summary <- summary(q5_model_price)

p5 <- ggplot(df, aes(x = Price, y = log_installs)) +
	geom_jitter(alpha = 0.25, width = 0.1, height = 0.1, color = "#2C3E50") +
	geom_smooth(method = "lm", se = FALSE, color = "#E45756", linewidth = 1.1) +
	labs(title = "Q5: Price vs Installs", x = "Price", y = "Log(Installs)") +
	base_plot
save_plot(p5, "Q5_price_vs_installs.png")

# Q6: Correlation between rating and installs
q6_cor <- cor.test(df$Rating, df$log_installs)

p6 <- ggplot(df, aes(x = Rating, y = log_installs)) +
	geom_jitter(alpha = 0.2, width = 0.02, height = 0.1, color = "#4C78A8") +
	geom_smooth(method = "lm", se = FALSE, color = "#F58518", linewidth = 1.1) +
	labs(title = "Q6: Rating vs Installs", x = "Rating", y = "Log(Installs)") +
	base_plot
save_plot(p6, "Q6_rating_vs_installs.png")

# Q7: Does review count influence installs independently?
q7_model_reviews <- lm(log_installs ~ Reviews + Rating + Category, data = df)
q7_model_reviews_summary <- summary(q7_model_reviews)

p7 <- ggplot(df, aes(x = log_reviews, y = log_installs)) +
	geom_jitter(alpha = 0.25, width = 0.08, height = 0.08, color = "#2C3E50") +
	geom_smooth(method = "lm", se = FALSE, color = "#E45756", linewidth = 1.1) +
	labs(title = "Q7: Reviews vs Installs", x = "Log(Reviews)", y = "Log(Installs)") +
	base_plot
save_plot(p7, "Q7_reviews_vs_installs.png")

# Q8: Is there a rating threshold for high success?
q8_logit <- glm(high_success ~ Rating, data = df, family = "binomial")
df$rating_bin <- cut(df$Rating, breaks = c(0, 3, 4, 4.5, 5), include.lowest = TRUE)
q8_bin_success <- aggregate(high_success ~ rating_bin, data = df, mean)

p8 <- ggplot(q8_bin_success, aes(x = rating_bin, y = high_success, group = 1)) +
	geom_line(color = "#54A24B", linewidth = 1.2) +
	geom_point(color = "#54A24B", size = 3) +
	labs(title = "Q8: Success Rate by Rating Bin", x = "Rating Bin", y = "High Success Rate") +
	base_plot
save_plot(p8, "Q8_rating_threshold_success.png")

# Q9: Are free apps more likely to be high-success than paid apps?
q9_table <- table(df$Type, df$high_success)
q9_chi <- chisq.test(q9_table)
q9_df <- as.data.frame(q9_table)
names(q9_df) <- c("Type", "HighSuccess", "Count")

p9 <- ggplot(q9_df, aes(x = Type, y = Count, fill = as.factor(HighSuccess))) +
	geom_col(position = "dodge") +
	scale_fill_manual(values = c("0" = "#B279A2", "1" = "#72B7B2"), name = "High Success") +
	labs(title = "Q9: High Success by App Type", x = "Type", y = "Count") +
	base_plot
save_plot(p9, "Q9_type_vs_high_success.png")

# Q10: Is there an optimal price range for paid apps?
paid_df <- df %>% filter(Type == "Paid", Price > 0)
paid_df$price_bin <- cut(paid_df$Price, breaks = c(0, 1, 5, 10, 50), include.lowest = TRUE)
q10_price_range <- aggregate(log_installs ~ price_bin, data = paid_df, mean)

p10 <- ggplot(q10_price_range, aes(x = price_bin, y = log_installs)) +
	geom_col(fill = "#ECA82C", alpha = 0.85) +
	labs(title = "Q10: Paid App Price Range vs Mean Installs", x = "Price Bin", y = "Mean Log(Installs)") +
	base_plot
save_plot(p10, "Q10_paid_price_bin_installs.png")

# Q11: Does app size influence installs?
q11_cor <- cor.test(df$Size, df$log_installs)
q11_model <- lm(log_installs ~ Size, data = df)
q11_model_summary <- summary(q11_model)

p11 <- ggplot(df, aes(x = Size, y = log_installs)) +
	geom_point(alpha = 0.2, color = "#4C78A8") +
	geom_smooth(method = "lm", se = FALSE, color = "#E45756", linewidth = 1.1) +
	labs(title = "Q11: Size vs Installs", x = "Size", y = "Log(Installs)") +
	base_plot
save_plot(p11, "Q11_size_vs_installs.png")

# Q12: Do recently updated apps perform better?
q12_model <- lm(log_installs ~ days_since_update, data = df)
q12_model_summary <- summary(q12_model)

p12 <- ggplot(df, aes(x = days_since_update, y = log_installs)) +
	geom_point(alpha = 0.2, color = "#2C3E50") +
	geom_smooth(method = "lm", se = FALSE, color = "#E45756", linewidth = 1.1) +
	labs(title = "Q12: Update Recency vs Installs", x = "Days Since Last Update", y = "Log(Installs)") +
	base_plot
save_plot(p12, "Q12_recency_vs_installs.png")

# Q13: Which categories have highest success rate (>=1M installs)?
q13_category_success <- aggregate(high_success ~ Category, data = df, mean)
q13_top <- q13_category_success %>% arrange(desc(high_success)) %>% slice_head(n = 10)

p13 <- ggplot(q13_top, aes(x = reorder(Category, high_success), y = high_success)) +
	geom_col(fill = "#54A24B", alpha = 0.85) +
	coord_flip() +
	labs(title = "Q13: Top Categories by Success Rate", x = "Category", y = "Success Rate") +
	base_plot
save_plot(p13, "Q13_top_category_success.png")

# Q14: Which factors best predict installs? (full linear model)
q14_model <- lm(log_installs ~ Category + log_reviews + Rating + Price + Size + Avg_Sentiment + days_since_update, data = df)
q14_summary <- summary(q14_model)
q14_coef <- as.data.frame(q14_summary$coefficients)
q14_coef$Feature <- rownames(q14_coef)

p14 <- ggplot(q14_coef %>% filter(Feature != "(Intercept)"), aes(x = reorder(Feature, Estimate), y = Estimate)) +
	geom_col(fill = "#4C78A8", alpha = 0.85) +
	coord_flip() +
	labs(title = "Q14: Linear Model Coefficients", x = "Feature", y = "Estimate") +
	base_plot
save_plot(p14, "Q14_linear_model_coefficients.png")

# Q15: Can we classify success with logistic regression?
df$Success <- as.factor(ifelse(df$Installs >= 1000000, 1, 0))

train_idx <- sample(seq_len(nrow(df)), size = floor(0.8 * nrow(df)))
train <- df[train_idx, ]
test <- df[-train_idx, ]

q15_logit <- glm(
	Success ~ Category + Rating + Reviews + Price + Size + Avg_Sentiment + days_since_update,
	data = train,
	family = "binomial"
)

q15_pred_prob <- predict(q15_logit, newdata = test, type = "response")
q15_pred_class <- ifelse(q15_pred_prob > 0.5, 1, 0)
q15_accuracy <- mean(q15_pred_class == as.numeric(as.character(test$Success)))

q15_conf_mat <- table(
	Predicted = factor(q15_pred_class, levels = c(0, 1)),
	Actual = factor(as.numeric(as.character(test$Success)), levels = c(0, 1))
)

tn <- q15_conf_mat["0", "0"]
tp <- q15_conf_mat["1", "1"]
fp <- q15_conf_mat["1", "0"]
fn <- q15_conf_mat["0", "1"]

q15_precision <- ifelse((tp + fp) == 0, NA, tp / (tp + fp))
q15_recall <- ifelse((tp + fn) == 0, NA, tp / (tp + fn))
q15_specificity <- ifelse((tn + fp) == 0, NA, tn / (tn + fp))
q15_f1 <- ifelse(is.na(q15_precision) || is.na(q15_recall) || (q15_precision + q15_recall) == 0,
								 NA,
								 2 * q15_precision * q15_recall / (q15_precision + q15_recall))

q15_roc_df <- data.frame(prob = q15_pred_prob, actual = as.numeric(as.character(test$Success)))

p15 <- ggplot(q15_roc_df, aes(x = prob, fill = as.factor(actual))) +
	geom_histogram(position = "identity", alpha = 0.5, bins = 30) +
	labs(title = "Q15: Predicted Success Probabilities", x = "Predicted Probability", y = "Count", fill = "Actual") +
	base_plot
save_plot(p15, "Q15_logit_predicted_probabilities.png")

# -----------------------------
# Save all key outputs for answers
# -----------------------------
write_csv(q1_summary, file.path(output_dir, "Q1_summary.csv"))
write_csv(q2_top_categories, file.path(output_dir, "Q2_top_categories.csv"))
write.csv(as.data.frame(q3_anova_summary[[1]]), file.path(output_dir, "Q3_anova_summary.csv"), row.names = TRUE)
write_csv(as.data.frame(q4_type_means), file.path(output_dir, "Q4_type_means.csv"))
write_csv(as.data.frame(q8_bin_success), file.path(output_dir, "Q8_rating_bin_success.csv"))
write_csv(as.data.frame(q9_df), file.path(output_dir, "Q9_type_high_success_counts.csv"))
write_csv(as.data.frame(q10_price_range), file.path(output_dir, "Q10_price_bin_installs.csv"))
write_csv(as.data.frame(q13_category_success), file.path(output_dir, "Q13_category_success.csv"))
write_csv(q14_coef, file.path(output_dir, "Q14_coefficients.csv"))

# Save model summaries
capture.output(q4_ttest, file = file.path(output_dir, "Q4_ttest.txt"))
capture.output(q5_model_price_summary, file = file.path(output_dir, "Q5_model_price_summary.txt"))
capture.output(q6_cor, file = file.path(output_dir, "Q6_correlation.txt"))
capture.output(q7_model_reviews_summary, file = file.path(output_dir, "Q7_model_reviews_summary.txt"))
capture.output(summary(q8_logit), file = file.path(output_dir, "Q8_logit_summary.txt"))
capture.output(q9_chi, file = file.path(output_dir, "Q9_chi_square.txt"))
capture.output(q11_cor, file = file.path(output_dir, "Q11_correlation.txt"))
capture.output(q11_model_summary, file = file.path(output_dir, "Q11_model_summary.txt"))
capture.output(q12_model_summary, file = file.path(output_dir, "Q12_model_summary.txt"))
capture.output(q14_summary, file = file.path(output_dir, "Q14_model_summary.txt"))
capture.output(summary(q15_logit), file = file.path(output_dir, "Q15_logit_model_summary.txt"))
capture.output(q15_conf_mat, file = file.path(output_dir, "Q15_confusion_matrix.txt"))
writeLines(
	c(
		paste("Q15 Accuracy:", round(q15_accuracy, 4)),
		paste("Q15 Precision:", round(q15_precision, 4)),
		paste("Q15 Recall:", round(q15_recall, 4)),
		paste("Q15 Specificity:", round(q15_specificity, 4)),
		paste("Q15 F1:", round(q15_f1, 4))
	),
	con = file.path(output_dir, "Q15_metrics.txt")
)

cat("All merged steps completed.\n")
cat("Processed dataset written to:", processed_path, "\n")
cat("Question outputs written to:", output_dir, "\n")
cat("Question plots written to:", plot_dir, "\n")
