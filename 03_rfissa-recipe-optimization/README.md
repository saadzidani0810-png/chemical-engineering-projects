# Rfissa recipe optimization: nutrition targets at minimum cost

**Problem.** Rfissa is a traditional Moroccan dish of chicken, lentils, onions, msemen/trid, fenugreek and spices. The task is to choose the grams per person of each ingredient so that:
- calories and protein reach their targets (700 kcal and 35 g by default);
- realistic culinary constraints hold;
- cost in MAD is as low as possible.

**Model.**
- **Variables:** 9 ingredient masses per person.
- **Objective:** weighted least squares on the calorie and protein targets, plus a taste penalty and a cost term.
- **Constraints:**
  - lower and upper bounds for each ingredient;
  - lentil/chicken ratio between 0.2 and 0.6;
  - total spices at most 6 g per person.
- **Solver:** SLSQP (`scipy.optimize.minimize`).
- **Sources:** nutrition values and recipe proportions are referenced in the notebook (USDA-based databases, recipe sites) and can be adjusted.

**Results (default case).**
- **Per person:** 699.9 kcal, 40.6 g protein, about 7.8 MAD.
- **Scaled to 6 people:** about 46.7 MAD.
- **Sensitivity:** with targets of 650 kcal and 32 g protein, cost drops to about 7.3 MAD per person.

**Limitations.**
- Nutrition data are averages.
- Fenugreek, which is characteristic of the dish, has a lower bound of zero, so the optimizer drops it. A minimum quantity is the obvious next constraint to add.

**Run.** `pip install -r requirements.txt`, then open `rfissa_optimization.ipynb`.

*Personal project. Notebook text is in French.*
