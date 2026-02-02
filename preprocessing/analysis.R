library(dplyr)
library(readr)

# Load the cleaned data
final_data <- read_csv("data/cleaned/final_data.csv")

# Remove rows with missing Success values
final_data <- final_data %>% filter(!is.na(Success))

# Display summary
str(final_data)
summary(final_data)

# Save the filtered data
write_csv(final_data, "data/cleaned/final_data_filtered.csv")

cat("Filtered dataset saved. Total apps:", nrow(final_data), "\n")
