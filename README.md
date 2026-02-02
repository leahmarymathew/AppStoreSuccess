# App Store Success Predictor – Data Cleaning Module

## Role
Leah – Data Cleaning, Transformation & Integration

## Description
This module performs data inspection, cleaning, transformation, and integration
on Google Play Store datasets to generate a final analysis-ready dataset
used by all other modules.

## Datasets
Raw datasets are not included due to licensing.
They can be downloaded from:
- https://www.kaggle.com/datasets/lava18/google-play-store-apps
- https://www.kaggle.com/datasets/prakharrathi25/google-play-store-reviews

## Output Files
- data/cleaned/apps_cleaned.csv
- data/cleaned/review_summary.csv
- data/cleaned/final_data.csv

## How to Run
```bash
Rscript preprocessing/data_cleaning.R
