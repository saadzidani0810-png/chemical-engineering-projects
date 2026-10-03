# Phosphoric acid (dihydrate process) model in Matlab and Aspen + 

**Context.** This is self-initiated work done during my observation internship at OCP Group, Jorf Lasfar (phosphoric acid Line 03 E, June to August 2026). It started from a DCS snapshot of the line.

**What the script does** (`Simulation_AcidePhosphorique.m`):
1. Steady-state mass and energy balance of the attack, filtration and flash-cooling section.
2. Element balances and KPIs: P₂O₅ yield, gypsum/P₂O₅ ratio and consumptions.
3. Optimization scenarios with simple parametric economics.
4. Sensitivity analysis (tornado chart).
5. Monte-Carlo uncertainty analysis.
6. A dynamic ODE model of the attack reactor and flash cooler.
7. Optimization of the operating variables, falling back to a grid search when the Optimization Toolbox is missing.

`Guide_Simulink_AcidePhosphorique.md` describes how to rebuild the model in Simulink. Example figures are in [`figures/`](figures/).

**Important caveats.**
- The ore composition and the base P₂O₅ yield (96%) are literature assumptions, not plant analyses.
- The kinetic and loss model is illustrative and uncalibrated.
- The results are order-of-magnitude learning results and are not intended for operating decisions.

**Run.** MATLAB R2016b or later: open and run `Simulation_AcidePhosphorique.m`.

*Comments and guide are in French.*
For the Aspen one open the aspen file and run 
