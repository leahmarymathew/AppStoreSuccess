# Load dataset
df <- read.csv("data/cleaned/final_data.csv", stringsAsFactors = FALSE)

# -------- 1. Ensure numeric --------
df$Installs <- as.numeric(df$Installs)
df$Reviews <- as.numeric(df$Reviews)
df$Rating <- as.numeric(df$Rating)
df$Price <- as.numeric(df$Price)
df$Size <- as.numeric(df$Size)

# -------- 2. Log transform installs --------
df$log_installs <- log1p(df$Installs)

# -------- 3. Factor conversion --------
df$Category <- as.factor(df$Category)
df$Type <- as.factor(df$Type)
df$Content.Rating <- as.factor(df$Content.Rating)

# -------- 4. Drop unnecessary column --------
df$Genres <- NULL

# -------- 5. Binary variables --------
df$is_free <- ifelse(df$Type == "Free", 1, 0)

# IMPORTANT (NEW)
df$high_success <- ifelse(df$Installs >= 1000000, 1, 0)

# -------- 6. Date processing --------
df$Last_Updated <- as.Date(df$Last.Updated, format="%B %d, %Y")

df$days_since_update <- as.numeric(Sys.Date() - df$Last_Updated)

# -------- 7. Handle missing --------
df <- na.omit(df)

# -------- 8. Save processed dataset --------
write.csv(df, "data/preprocessed/processed_appstore.csv", row.names = FALSE)

cat("Preprocessing completed successfully!")