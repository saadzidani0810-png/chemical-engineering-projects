# Coupling seawater reverse osmosis with PEM electrolysis (1 Mt H₂/year)

**Problem.** Size a green-hydrogen system that produces 1 million tonnes of H₂ per year. Seawater is purified by reverse osmosis (RO) before feeding PEM electrolyzers. The study compares:
- capacity factors (CF) of 80% (wind plus storage) and 50% (wind only);
- RO recovery ratios (RR) of 45%, 50% and 60%;
- current densities of 0.2 and 0.6 A/cm².

**Method.**
- **Electrolyzer sizing:** from Faraday's law (current, active area, number of stacks, power), using cell voltages from an earlier electrochemical loss model.
- **Water balance:** about 1,020 m³/h of desalinated water.
- **RO model:** a 0-D WaterTAP/IDAES unit model (Pyomo) with high-pressure pump, membrane module and energy-recovery device. It gives specific energy consumption and costing for each RR.
- **Cases:** six CF/RR combinations, then a global comparison.

**Results.**
- **Capacity factor dominates sizing.** At 0.6 A/cm², the active area rises from 6.4 × 10⁵ m² (CF 80%) to 1.0 × 10⁶ m² (CF 50%).
- **Best recovery ratio:** RR = 50% gives the lowest RO specific energy, 2.35 kWh/m³.
- **Desalination is negligible:** about 2.4–2.5 MW, against 7–13 GW for electrolysis.
- **Recommended configuration:** CF 80%, j = 0.6 A/cm², RR 50%.

**Run.** The notebook was developed on Google Colab:
1. `pip install -r requirements.txt`
2. `idaes get-extensions` (installs the solvers)
3. Open `ro_pem_coupling_watertap.ipynb`.

*Integrative Project course (UM6P). The RO model follows the course material on desalination modeling with Pyomo, IDAES and WaterTAP.*
