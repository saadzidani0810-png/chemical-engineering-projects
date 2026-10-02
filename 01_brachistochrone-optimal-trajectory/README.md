# Brachistochrone: optimal descent trajectory

**Problem.** Find the curve along which a bead slides without friction from A(0, y_A) to B(l, 0) in the shortest time, and compare it with the straight line AB.

**Method.**
- Euler–Lagrange (Beltrami identity) shows the optimum is a cycloid, x = R(t − sin t), y = y_A − R(1 − cos t).
- The end condition f(t_f) = 0 is solved numerically with `scipy.optimize` to get t_f, then R and k = 2R.
- Travel times are computed in closed form, T = √(R/g)·t_f, and compared with the straight-line time.
- The sampled trajectory and a summary table are exported to CSV with pandas.

**Result (default parameters).** The cycloid takes 0.583 s against 0.639 s for the straight line, about 9% faster.

**Known limitation.** The numerical cross-check of the cycloid time returns NaN because the speed is zero at the start point (division by zero at t = 0). The closed-form value is unaffected. Starting the integration at a small t > 0 would fix it.

**Run.** `pip install -r requirements.txt`, then open `brachistochrone_optimal_trajectory.ipynb`. Change y_A, l and g in the "Paramètres utilisateur" cell.

*Notebook text is in French.*
