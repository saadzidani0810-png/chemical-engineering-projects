# Guide Simulink — Modélisation dynamique du procédé d'acide phosphorique (ligne 03 E)

**But** : transformer les équations de description du système en un modèle **état‑espace / ODE** exploitable dans **Simulink**, puis construire pas à pas le schéma‑bloc (réacteur d'attaque + flash cooler + régulation + recyclage + filtration).

> Ce guide est le pendant graphique du fichier `Simulation_AcidePhosphorique.m` (fonction `attackODE`). Le modèle est **illustratif** : les constantes cinétiques et les coefficients de pertes doivent être **calibrés** sur données réelles avant tout usage prédictif. Statuts : [mesuré] DCS / [estimation] littérature. Aucune application sans HAZOP + MOC + validation site.

---

## 1. Étape 1 — Écrire le système sous forme d'état

### 1.1 Vecteur d'état, entrées, paramètres

**États** `z ∈ ℝ⁶` (grandeurs conservatives dans le réacteur d'attaque 03EM01, hypothèse « bien mélangé ») :

| Symbole | Signification | Unité |
|---|---|---|
| z₁ = m_P | masse de P₂O₅ dissous (liquide) | kg |
| z₂ = m_Ca | masse de CaO non encore réagi | kg |
| z₃ = m_Gyp | masse de gypse solide en suspension | kg |
| z₄ = m_A | masse de H₂SO₄ libre | kg |
| z₅ = m_W | masse d'eau | kg |
| z₆ = T | température de la bouillie | °C |

**Entrées** `u` : `F_rock` (kg/s roche), `F_acid` (kg/s H₂SO₄ pur), `T_rock`, `T_acid`, `T_set` (consigne T).
**Paramètres** `p` : compositions (xP, xCa…), masses molaires M, ΔHr, ΔHdil, λ, Cp, k₀, Eₐ, K_m, τ (temps de séjour).

### 1.2 Loi de vitesse (cinétique d'attaque)

Attaque du CaO de l'apatite par l'acide libre (forme saturante en acide) :

$$ r_{Ca} = k_0\,e^{-E_a/(R\,T_K)}\; m_{Ca}\; \frac{C_A}{C_A+K_m}, \qquad C_A=\frac{m_A}{m_W+m_A},\quad T_K=T+273{,}15 $$

Le P₂O₅ est libéré proportionnellement au CaO attaqué (ratio de la roche `xP/xCa`).

### 1.3 Équations de bilan (forme ODE `dz/dt = f(z,u,p)`)

$$
\begin{aligned}
\dot m_P   &= F_{rock}\,x_P \;-\; \tfrac{m_P}{\tau} \\
\dot m_{Ca}&= F_{rock}\,x_{Ca} \;-\; r_{Ca} \;-\; \tfrac{m_{Ca}}{\tau} \\
\dot m_{Gyp}&= r_{Ca}\,\tfrac{M_{gyp}}{M_{CaO}} \;-\; \tfrac{m_{Gyp}}{\tau} \\
\dot m_A   &= F_{acid} \;-\; r_{Ca}\,\tfrac{M_{H_2SO_4}}{M_{CaO}} \;-\; \tfrac{m_A}{\tau} \\
\dot m_W   &= F_{W,in} \;-\; \tfrac{Q_{flash}}{\lambda} \;-\; \tfrac{m_W}{\tau} \\
\dot T     &= \dfrac{Q_{gen}-Q_{flash}+Q_{dil}}{m_{tot}\,C_p}
\end{aligned}
$$

avec les termes de chaleur :

$$ Q_{gen}=r_{Ca}\,\frac{\Delta H_r}{M_{CaO}},\qquad Q_{dil}=F_{acid}\,\frac{\Delta H_{dil}}{M_{H_2SO_4}},\qquad m_{tot}=\textstyle\sum_i m_i $$

et l'évacuation par le **flash cooler** pilotée en boucle fermée (voir §3) :

$$ Q_{flash}=\text{PID}\big(T-T_{set}\big) $$

`F_{W,in}` = eau associée à la pulpe = `F_rock·(1−φ)/φ` (φ = taux de solides = 0,61 [mesuré]).

### 1.4 Sorties (équations algébriques)

$$ S(\%)=100\,\frac{m_A}{m_W+m_A}\ \text{(sulfate libre)},\qquad
\eta=1-\varepsilon_{sol}(L)-\varepsilon_{cc}(S)-\varepsilon_{insol} $$

$$ \varepsilon_{sol}=\varepsilon_{sol}^0\,e^{-\alpha(L-1)},\qquad
\varepsilon_{cc}=\varepsilon_{cc}^0\big(1+\beta(S-S^\*)^2\big) $$

$$ \dot P_{2}O_{5}^{prod}=\eta\,(F_{rock}\,x_P) $$

`L` = ratio d'eau de lavage (variable de conduite de la filtration) ; `S*` ≈ 2,5 % (optimum de sulfate libre).

---

## 2. Étape 2 — Construire le modèle dans Simulink

Deux approches ; **l'approche A (MATLAB Function) est la plus simple et fidèle** au fichier `.m`.

### 2.1 Approche A — bloc « MATLAB Function » (recommandée)

1. **Nouveau modèle** Simulink (`simulink` → Blank Model). Régler le solveur : *Model Settings → Solver = ode45 (variable‑step)*, *Stop time = 3600 s*.
2. Insérer un bloc **MATLAB Function** (bibliothèque *User‑Defined Functions*). Coller le code ci‑dessous : il renvoie `dz` à partir de `z`, `u`.
3. Insérer un bloc **Integrator** (vecteur, dimension 6) : entrée `dz`, sortie `z`. Condition initiale = `z0` (vecteur 6×1).
4. Boucler `z` (sortie de l'intégrateur) vers l'entrée `z` du MATLAB Function.
5. Créer les entrées `u` : blocs **Constant** ou **Signal Builder** (F_rock, F_acid, T_set…) regroupés par un **Mux**.
6. **Sorties/scopes** : `Demux` sur `z` → **Scope** (T, masses). Ajouter un bloc MATLAB Function « sorties » calculant `S` et `η` (§1.4) → Scope/Display.
7. Lancer ; ajuster `z0` et les gains.

```matlab
function dz = attack_fcn(z, u)
%#codegen
% z=[mP;mCa;mGyp;mA;mW;T]  u=[Frock;Facid;Tset]  (SI: kg/s, C)
  mP=z(1); mCa=z(2); mGyp=z(3); mA=max(z(4),0); mW=max(z(5),1); T=z(6);
  Frock=u(1); Facid=u(2); Tset=u(3);
  % --- parametres (a calibrer) ---
  xP=0.32; xCa=0.50; phi=0.61;
  M_CaO=56.08; M_H2SO4=98.08; M_Gyp=172.2;
  dHr=122e3/M_CaO;      % J/kg CaO  (kJ/mol -> J/kg)
  dHdil=50e3/M_H2SO4;   % J/kg H2SO4
  lambda=2308e3;        % J/kg  (kJ/kg -> J/kg)
  Cp=3000;              % J/kg.K
  k0=2.0e6; Ea=45e3; Rg=8.314; Km=0.03; tau=1800;
  % --- cinetique ---
  CA=mA/(mW+mA); TK=T+273.15;
  rCa=k0*exp(-Ea/(Rg*TK))*mCa*CA/(CA+Km);
  rCa=min(rCa, mCa/10);
  % --- feeds ---
  Fca=Frock*xCa; FP=Frock*xP; FW=Frock*(1-phi)/phi;
  % --- flash cooler (regulation simple ; remplacer par bloc PID) ---
  Qgen=rCa*dHr;                       % W
  Kc=5e3;                             % gain W/K
  Qflash=max(0, Kc*(T-Tset) + 0.9*Qgen);
  Qdil=Facid*dHdil;                   % W
  mtot=mP+mCa+mGyp+mA+mW;
  % --- ODE ---
  dmP  = FP - mP/tau;
  dmCa = Fca - rCa - mCa/tau;
  dmGyp= rCa*M_Gyp/M_CaO - mGyp/tau;
  dmA  = Facid - rCa*M_H2SO4/M_CaO - mA/tau;
  dmW  = FW - Qflash/lambda - mW/tau;
  dT   = (Qgen - Qflash + Qdil)/(mtot*Cp);
  dz=[dmP;dmCa;dmGyp;dmA;dmW;dT];
end
```

### 2.2 Approche B — blocs élémentaires (pédagogique)

Reconstruire chaque équation avec **Sum / Gain / Product / Integrator** :
- 6 **Integrator** (un par état) ; leur sortie alimente les blocs de calcul des dérivées.
- La vitesse `r_Ca` : blocs **Math Function (exp)**, **Product**, **Divide**, **Gain** (k₀, Eₐ/R).
- Les termes `−mᵢ/τ` : **Gain** (1/τ) rebouclés en soustraction (**Sum**).
- Le bilan thermique : **Product/Divide** pour `1/(m_tot·Cp)`, **Sum** des chaleurs.
- **Avantage** : visualisation physique ; **inconvénient** : lourd. Réserver aux blocs clés (ex. juste le bilan thermique) et garder le reste en MATLAB Function.

---

## 3. Étape 3 — Régulation du flash cooler (boucle fermée)

Remplacer le `Q_flash` interne par une **vraie boucle** :
- Prélever `T` (sortie), le comparer à `T_set` via un **Sum** (erreur `e=T−T_set`).
- Bloc **PID Controller** → sortie `Q_flash` (bornée ≥ 0 par un bloc **Saturation**).
- Réinjecter `Q_flash` dans le MATLAB Function comme entrée supplémentaire (au lieu du calcul interne).
- **Réglage** : commencer P seul (Kp ≈ 5·10³ W/K), ajouter I pour annuler l'écart statique. Consigne `T_set` = 90,6 °C [mesuré TI‑232].

---

## 4. Étape 4 — Recyclage (acide de retour) et filtration

- **Recyclage** : la filtration renvoie l'« acide de retour » vers l'attaque (FIC‑568 = 268,9 m³/h [mesuré]). Modéliser par une **rétroaction** : sortie liquide → **Transport Delay** (temps de transit) → ajout aux feeds `F_acid`/`m_P` d'entrée. Utiliser un **tear/Memory** pour amorcer la boucle et éviter la boucle algébrique.
- **Filtration/rendement** : bloc **MATLAB Function** appliquant `η = recoveryModel(S,L)` (§1.4) sur la sortie ; `S` calculé depuis `m_A,m_W`, `L` en entrée de conduite. Sortie `P₂O₅ produit = η·F_rock·xP` → Scope.

---

## 5. Étape 5 — Vérification et calibration

1. **Cohérence statique** : à l'équilibre (dz/dt≈0), vérifier que `η`, le ratio gypse/P₂O₅ (~5,0) et l'excès H₂SO₄ (~−6,6 %) retrouvent la baseline du `.m` (§2 du rapport).
2. **Calibration** : ajuster `k₀, Eₐ, K_m, τ` pour reproduire T (90,6 °C) et la densité de bouillie mesurées ; ajuster `ε⁰, α, β, S*` sur les analyses labo du gâteau (pertes P₂O₅). **Sans ces mesures, le modèle reste qualitatif.**
3. **Validation** : comparer sur un jeu de données distinct (autre instantané DCS) ; suivre RMSE et biais.

---

## 6. Correspondance équations ↔ blocs (récapitulatif)

| Équation (§1.3) | Bloc Simulink principal | Notes |
|---|---|---|
| `ṁ_P, ṁ_Ca, ṁ_Gyp, ṁ_A, ṁ_W` | Integrator (×5) + MATLAB Function | états massiques |
| `Ṫ` | Integrator + Sum/Divide | bilan thermique |
| `r_Ca` (Arrhenius) | Math Function (exp), Product | cinétique |
| `Q_flash` | PID + Saturation | régulation T |
| recyclage | Transport Delay + Sum + Memory | tear stream |
| `η(S,L)`, P₂O₅ produit | MATLAB Function + Scope | sorties |

Schéma‑bloc de principe : voir [`figures/Schema_Simulink_Blocs.png`](figures/Schema_Simulink_Blocs.png).

---

## 7. Limites du modèle

- Réacteur supposé **unique et bien mélangé** (la réalité : compartiments + maturation + boucle de recirculation) ; extensible en cascade de CSTR.
- Cinétique et pertes **illustratives** (à calibrer) ; pas de bilan population de cristaux (habit/taille non modélisés).
- Thermo simplifiée (pas d'électrolytes détaillés — c'est le rôle d'Aspen ELECNRTL ; Simulink capte la **dynamique/contrôle**, pas la spéciation ionique fine).
- Usage visé : **dynamique, régulation, ordres de grandeur, essais de conduite** — complémentaire (non substitut) d'un modèle thermodynamique rigoureux.
