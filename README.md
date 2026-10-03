# Chemical Engineering Projects: Saad Zidani

Process engineering, optimization and data projects from my studies at Université Mohammed VI Polytechnique (UM6P), College of Chemical Sciences and Engineering, School of Chemical Sciences and Engineering, Ben Guerir, Morocco.

| # | Project | Tools | What it shows |
|---|---------|-------|---------------|
| 01 | [Brachistochrone: optimal trajectory](01_brachistochrone-optimal-trajectory/) | Python, NumPy, SciPy, pandas | Calculus of variations solved numerically; cycloid vs. straight-line descent time |
| 02 | [Cancer severity regression](02_cancer-severity-regression/) | Python, pandas, scikit-learn, seaborn | Data preprocessing, EDA, linear regression vs. decision tree, feature importance |
| 03 | [Rfissa recipe optimization](03_rfissa-recipe-optimization/) | Python, SciPy (SLSQP) | Constrained nonlinear optimization of nutrition targets and cost, with sensitivity analysis |
| 04 | [Seawater RO and PEM electrolysis coupling](04_ro-pem-electrolysis-coupling/) | Python, Pyomo, IDAES, WaterTAP | Sizing a 1 Mt/yr green-hydrogen system and its desalination unit |
| 05 | [Phosphoric acid process model](05_phosphoric-acid-process-Matlab-Aspen/) | MATLAB, Simulink and aspen| Mass and energy balances, sensitivity, Monte-Carlo uncertainty and a dynamic model of a wet-process (dihydrate) plant |

Each folder has its own README with the problem, method, results and how to run it.

## Running the Python notebooks

```bash
pip install -r 01_brachistochrone-optimal-trajectory/requirements.txt   # or the file of the project you want
jupyter notebook
```

Project 04 needs the IDAES solver extensions (`idaes get-extensions`); it was developed on Google Colab.

## Contact

Saad Zidani · Saad.ZIDANI@um6p.ma · [LinkedIn](https://www.linkedin.com/in/saad-zidani-2b1440336/)
