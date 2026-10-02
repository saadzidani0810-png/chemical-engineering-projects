# Predicting cancer severity: regression mini-project

**Problem.** Predict a patient's `Target_Severity_Score` from demographic, lifestyle, environmental and clinical features. The dataset has 50,000 patient records from 2015 to 2024, with 15 columns.

**Method.**
1. Preprocessing: categorical encoding, feature scaling and an 80/20 train/test split.
2. Exploratory analysis: distributions, correlation matrix, and severity by cancer type, stage and country.
3. Models: linear regression and a decision tree regressor (scikit-learn).
4. Evaluation: MAE, RMSE and R², predicted vs. actual plots, decision-tree feature importance and linear-regression coefficients.

**Results.**

| Model | MAE | RMSE | R² |
|---|---|---|---|
| Linear regression | 0.0025 | 0.0029 | 0.99999 |
| Decision tree | 0.289 | 0.364 | 0.907 |

- **Main drivers:** smoking, genetic risk and treatment cost come out as the strongest predictors.
- **Weak drivers:** age, gender, country and year have almost no influence.

**Interpretation note.** An R² of 0.99999 means the score is almost exactly a linear combination of the input features. The model is therefore recovering how the dataset was built. It should not be read as a clinical finding.

**Data.** Download `global_cancer_patients_2015_2024.csv` from Kaggle ([global-cancer-patients-2015-2024](https://www.kaggle.com/datasets/zahidmughal2343/global-cancer-patients-2015-2024)) and place it next to the notebook. The CSV is not stored in this repository.

**Run.** `pip install -r requirements.txt`, then open `cancer_severity_regression.ipynb`.

*Course mini-project (UM6P, Python and data analysis), done as a team. Analysis text is mostly in French.*
