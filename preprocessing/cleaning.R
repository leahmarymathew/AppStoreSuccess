
library(dplyr)
library(stringr)
library(readr)

apps <- read_csv("data/raw/googleplaystore.csv")
reviews <- read_csv("data/raw/googleplaystore_user_reviews.csv")

str(apps)
summary(apps)

str(reviews)
summary(reviews)

apps_clean <- apps %>%
  filter(!is.na(Category), !is.na(Rating))


apps_clean <- apps_clean %>%
  distinct(App, .keep_all = TRUE)

apps_clean$Reviews <- as.numeric(apps_clean$Reviews)

apps_clean$Installs <- apps_clean$Installs %>%
  str_replace_all("\\+", "") %>%
  str_replace_all(",", "") %>%
  as.numeric()

apps_clean$Price <- apps_clean$Price %>%
  str_replace("\\$", "") %>%
  as.numeric()

apps_clean$Size <- apps_clean$Size %>%
  str_replace("k", "") %>%
  str_replace("M", "") %>%
  as.numeric()

apps_clean$Size[apps_clean$Size == "Varies with device"] <- NA

apps_clean$Category <- as.factor(apps_clean$Category)
apps_clean$Type <- as.factor(apps_clean$Type)
apps_clean$`Content Rating` <- as.factor(apps_clean$`Content Rating`)
apps_clean$Genres <- as.factor(apps_clean$Genres)

write_csv(apps_clean, "data/cleaned/apps_cleaned.csv")

reviews_clean <- reviews %>%
  filter(!is.na(Translated_Review))

reviews_clean <- reviews_clean %>%
  select(App, Sentiment_Polarity)

reviews_clean$Sentiment_Polarity[is.na(reviews_clean$Sentiment_Polarity)] <- 0

review_summary <- reviews_clean %>%
  group_by(App) %>%
  summarise(
    Avg_Sentiment = mean(Sentiment_Polarity),
    Review_Count = n()
  )

write_csv(review_summary, "data/cleaned/review_summary.csv")

final_data <- apps_clean %>%
  left_join(review_summary, by = "App")

final_data$Avg_Sentiment[is.na(final_data$Avg_Sentiment)] <- 0
final_data$Review_Count[is.na(final_data$Review_Count)] <- 0

final_data$Success <- ifelse(final_data$Installs >= 1000000, 1, 0)
final_data$Success <- as.factor(final_data$Success)

str(final_data)
summary(final_data)
sum(is.na(final_data))

write_csv(final_data, "data/cleaned/final_data.csv")
