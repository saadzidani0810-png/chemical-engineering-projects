%% =====================================================================
%  SIMULATION_ACIDEPHOSPHORIQUE.m
%  Simulation du procede de production d'acide phosphorique (voie dihydrate)
%  Ligne 03 E - OCP Jorf Lasfar  --  ALTERNATIVE MATLAB a Aspen Plus
%
%  Contenu :
%    1) Donnees & hypotheses (tracables : [mesure] DCS / [estimation] litt.)
%    2) Bilan matiere & energie en regime permanent (analytique)
%    3) Bilans par element + KPI (rendement, ratios, consommations)
%    4) Scenarios d'optimisation + economie parametrique
%    5) Analyse de sensibilite (tornado)
%    6) Incertitude (Monte-Carlo)
%    7) Modele DYNAMIQUE (ODE) : reacteur d'attaque + flash cooler
%    8) Optimisation des variables operatoires (max rendement)
%
%  AVERTISSEMENT : la composition du minerai et le rendement de base (96%)
%  sont des HYPOTHESES (litterature) ; le modele cinetique/pertes est
%  ILLUSTRATIF et doit etre CALIBRE sur donnees reelles avant tout usage
%  predictif. Aucune modification industrielle sans HAZOP + MOC + site.
%
%  Compatibilite : MATLAB R2016b+ (fonctions locales dans un script).
%  Sans Optimization Toolbox : le code bascule sur une recherche par grille.
%  Auteur : etude procedes GUP+/UM6P - v1.0 - 2026-07-29
%% =====================================================================
clear; clc; close all;

%% ---------------------------------------------------------------------
%% 1) DONNEES & HYPOTHESES  (struct P)
%% ---------------------------------------------------------------------
P = struct();
% --- Entrees mesurees (DCS Yokogawa, 14/07/2026 09:30-09:33) ----------
P.F_rock   = 257.7;   % t/h  phosphate sec vers attaque      [mesure FIC-035]
P.Q_acid   = 119.5;   % m3/h debit H2SO4                     [mesure FI-200]
P.rho_acid = 1.816;   % t/m3 densite H2SO4 97%               [estimation Perry]
P.w_acid   = 0.97;    % -    titre massique H2SO4            [mesure CI-215]
P.phi_sol  = 0.61;    % -    taux de solides sousverse       [mesure TAUX_SOL]
P.Qsw      = 1102;    % m3/h eau de mer condenseur           [mesure FI-396]
P.Tsw_out  = 51.3;    % C    T sortie eau de mer             [mesure TI-395]
P.Tsw_in   = 25;      % C    T entree eau de mer             [estimation]
P.T_react  = 90.6;    % C    T reacteur                      [mesure TI-232]

% --- Composition du minerai (LITTERATURE - ESTIMATION) ----------------
P.xP   = 0.32;   % fraction massique P2O5   [estimation Khouribga]
P.xCa  = 0.50;   % fraction massique CaO    [estimation]
P.xCO2 = 0.05;   % fraction massique CO2    [estimation]
P.xF   = 0.035;  % fraction massique F      [estimation]
P.xSi  = 0.03;   % fraction massique SiO2   [estimation]

% --- Hypotheses procede ----------------------------------------------
P.eta0  = 0.96;  % rendement P2O5 de base (hypothese standard DH)
P.wacid_prod = 0.29; % titre massique acide produit (~29% P2O5) [estimation]
P.hum   = 0.30;  % humidite gateau gypse [estimation]

% --- Constantes physico-chimiques ------------------------------------
P.M.P2O5=141.9; P.M.CaO=56.08; P.M.CO2=44.01; P.M.H2SO4=98.08;
P.M.H3PO4=98.0; P.M.H2O=18.02; P.M.Gypse=172.2;
P.dHr   = 122;   % kJ/mol CaO  (exothermique, |dHr|)     [NIST]
P.dHdil = 50;    % kJ/mol H2SO4 dilution                  [Perry]
P.lambda= 2308;  % kJ/kg chaleur latente eau ~80C         [tables]
P.Cp_sw = 4.0;   % kJ/kg.K eau de mer

% --- Economie (parametrique) -----------------------------------------
P.price_P2O5 = 1000;  % $/t P2O5 valeur marginale (central 700-1500)
P.hours      = 7900;  % h/an (disponibilite ~0.9)

fprintf('===== SIMULATION ACIDE PHOSPHORIQUE - LIGNE 03 E =====\n\n');

%% ---------------------------------------------------------------------
%% 2) BILAN MATIERE & ENERGIE - REGIME PERMANENT
%% ---------------------------------------------------------------------
R = steadyState(P);

fprintf('--- 2. BILAN MATIERE (regime permanent) ---\n');
fprintf('H2SO4 pur              = %8.2f t/h\n', R.H2SO4pur);
fprintf('P2O5 entrant          = %8.2f t/h\n', R.P2O5in);
fprintf('CaO entrant           = %8.2f t/h\n', R.CaOin);
fprintf('n(CaO)                = %8.1f kmol/h\n', R.nCaO);
fprintf('Gypse sec             = %8.2f t/h\n', R.gypse);
fprintf('H2SO4 stoechiometrique= %8.2f t/h\n', R.H2SO4st);
fprintf('Exces H2SO4           = %8.2f %%\n', R.excess);
fprintf('P2O5 recupere         = %8.2f t/h\n', R.P2O5rec);
fprintf('Perte P2O5            = %8.2f t/h\n', R.lossP);
fprintf('H3PO4 100%%            = %8.2f t/h\n', R.H3PO4);
fprintf('Solution acide 29%%    = %8.2f t/h\n', R.acidsol);
fprintf('Gateau gypse humide   = %8.2f t/h\n', R.gyp_wet);
fprintf('Eau evaporee (flash)  = %8.2f t/h\n', R.evap);
fprintf('Eau fraiche (ferm.)   = %8.2f t/h\n', R.water_make);
fprintf('Fermeture masse (E-S) = %8.3f t/h  (~0 attendu)\n', R.close);

fprintf('\n--- 2b. BILAN ENERGIE ---\n');
fprintf('Chaleur reaction      = %8.2f MW\n', R.Qr);
fprintf('Chaleur dilution      = %8.2f MW\n', R.Qd);
fprintf('Chaleur totale        = %8.2f MW\n', R.Qtot);
fprintf('Duty condenseur (mer) = %8.2f MW\n', R.duty_cond);

%% ---------------------------------------------------------------------
%% 3) BILANS PAR ELEMENT + KPI
%% ---------------------------------------------------------------------
fprintf('\n--- 3. KPI ---\n');
fprintf('Rendement P2O5 (eta)  = %8.2f %%\n', R.eta*100);
fprintf('Conso spec. roche     = %8.3f t/t P2O5\n', P.F_rock/R.P2O5rec);
fprintf('Conso spec. H2SO4     = %8.3f t/t P2O5\n', R.H2SO4pur/R.P2O5rec);
fprintf('Ratio gypse/P2O5      = %8.3f t/t\n', R.gypse/R.P2O5rec);

% Repartition estimee des pertes (a confirmer par analyse labo)
frac = struct('soluble',0.45,'cocryst',0.40,'insol',0.15);
fprintf('Perte soluble (lavage)= %8.2f t/h (%.0f%%)\n', R.lossP*frac.soluble,100*frac.soluble);
fprintf('Perte co-cristallisee = %8.2f t/h (%.0f%%)\n', R.lossP*frac.cocryst,100*frac.cocryst);
fprintf('Perte non attaquee    = %8.2f t/h (%.0f%%)\n', R.lossP*frac.insol,100*frac.insol);

%% ---------------------------------------------------------------------
%% 4) SCENARIOS D'OPTIMISATION + ECONOMIE
%% ---------------------------------------------------------------------
fprintf('\n--- 4. SCENARIOS ---\n');
names = {'Cas0 Reference','Cas1 Operatoire','Cas2 Equipements',...
         'Cas3 APC','Cas4 Majeur','Cas5 Integre'};
deta  = [0, 1.2, 1.6, 0.7, 2.7, 2.0];      % gain de rendement (points)
capex = [0, 0.4, 6.0, 2.0, 55.0, 4.5];     % M$
fprintf('%-18s %6s %7s %10s %8s %9s %8s\n',...
        'Scenario','d_eta','eta%','dP2O5t/an','CAPEX','Gain M$/an','PB(an)');
Sc = struct();
for i=1:numel(names)
    eta_i  = min(0.99, P.eta0 + deta(i)/100);
    dP     = (eta_i - P.eta0)*R.P2O5in;         % t/h supplementaire
    dP_an  = dP*P.hours;                         % t/an
    gain   = dP_an*P.price_P2O5/1e6;             % M$/an
    if gain>0, pb=capex(i)/gain; else, pb=NaN; end
    Sc.eta(i)=eta_i; Sc.dP_an(i)=dP_an; Sc.gain(i)=gain; Sc.pb(i)=pb;
    fprintf('%-18s %6.1f %7.1f %10.0f %8.1f %9.2f %8.2f\n',...
        names{i}, deta(i), eta_i*100, dP_an, capex(i), gain, pb);
end

% Figure : gain vs CAPEX
figure('Name','Scenarios','Color','w');
scatter(capex(2:end), Sc.gain(2:end), 90, 'filled'); grid on; hold on;
text(capex(2:end)+0.6, Sc.gain(2:end), names(2:end),'FontSize',8);
xlabel('CAPEX (M$)'); ylabel('Gain brut (M$/an, central)');
title('Scenarios d''optimisation - gain vs CAPEX');

%% ---------------------------------------------------------------------
%% 5) ANALYSE DE SENSIBILITE (tornado)  sur P2O5 recupere
%% ---------------------------------------------------------------------
fprintf('\n--- 5. SENSIBILITE (P2O5 recupere) ---\n');
baseP = R.P2O5rec;
vars  = {'xP','eta0','F_rock'};
lo    = [0.30, 0.94, 245];    % bornes basses
hi    = [0.34, 0.98, 270];    % bornes hautes
delta = zeros(numel(vars),2);
for k=1:numel(vars)
    Plo=P; Plo.(vars{k})=lo(k); rlo=steadyState(Plo);
    Phi=P; Phi.(vars{k})=hi(k); rhi=steadyState(Phi);
    delta(k,:)=[rlo.P2O5rec-baseP, rhi.P2O5rec-baseP];
    fprintf('%-8s  bas=%+6.2f  haut=%+6.2f  t/h P2O5\n',vars{k},delta(k,1),delta(k,2));
end
figure('Name','Tornado','Color','w');
barh(1:numel(vars),delta,'stacked'); set(gca,'YTick',1:numel(vars),'YTickLabel',vars);
xlabel('\Delta P2O5 recupere (t/h)'); title('Tornado - sensibilite'); grid on;

%% ---------------------------------------------------------------------
%% 6) INCERTITUDE (Monte-Carlo) sur le gain du Cas 5
%% ---------------------------------------------------------------------
fprintf('\n--- 6. MONTE-CARLO (Cas 5) ---\n');
N=5000; rng(1);
xP_s   = 0.30 + (0.34-0.30)*rand(N,1);           % uniforme
deta_s = 1.5 + (2.5-1.5)*rand(N,1);              % gain points (plafonne)
price_s= triangular(700,1000,1500,N);            % $/t
hours_s= 7000 + (8200-7000)*rand(N,1);
gain_s = (deta_s/100).*(P.F_rock.*xP_s).*hours_s.*price_s/1e6;
fprintf('Gain Cas5  P5=%.1f  median=%.1f  P95=%.1f  M$/an\n',...
        prctile(gain_s,5), median(gain_s), prctile(gain_s,95));
figure('Name','MonteCarlo','Color','w');
histogram(gain_s,40); xlabel('Gain (M$/an)'); ylabel('Frequence');
title('Monte-Carlo - gain Cas 5'); grid on;

%% ---------------------------------------------------------------------
%% 7) MODELE DYNAMIQUE (ODE) : reacteur d'attaque + flash cooler
%%    Etats z = [mP ; mCa ; mGyp ; mH2SO4 ; mW ; T]   (kg, kg, kg, kg, kg, C)
%%    Voir guide Simulink pour la mise en equation detaillee.
%% ---------------------------------------------------------------------
fprintf('\n--- 7. SIMULATION DYNAMIQUE (ode45) ---\n');
u = struct();                       % entrees (feeds) en kg/s
u.Frock = P.F_rock*1000/3600;       % kg/s de roche
u.Facid = R.H2SO4pur*1000/3600;     % kg/s H2SO4 pur
u.Trock = 56.9; u.Tacid = 25;       % C
u.Tset  = P.T_react;                % consigne T (flash cooler)
% Etat initial (demarrage a mi-charge)
V0 = 3000;                          % m3 volume reacteur (hypothese)
rho= 1500;                          % kg/m3 bouillie
z0 = [ 0.29*0.5*V0*rho*0.001*1000;  % mP  (approx, kg P2O5)  -- initialisation grossiere
       P.F_rock*P.xCa*1000/3600*60; % mCa disponible initial
       0.2*V0*rho;                  % mGyp initial
       5000;                        % mH2SO4 libre initial
       0.5*V0*rho;                  % mW initial
       80 ];                        % T initial (C)
tspan = [0 3600];                   % 1 h simulee (s)
opts = odeset('RelTol',1e-5,'AbsTol',1e-3,'NonNegative',1:5);
[t,z] = ode45(@(t,z) attackODE(t,z,P,u), tspan, z0, opts);
figure('Name','Dynamique','Color','w');
subplot(2,1,1); plot(t/60, z(:,[1 3 4]),'LineWidth',1.3); grid on;
legend('m P2O5 (kg)','m Gypse (kg)','m H2SO4 libre (kg)','Location','best');
xlabel('temps (min)'); ylabel('masse (kg)'); title('Reacteur d''attaque - dynamique');
subplot(2,1,2); plot(t/60, z(:,6),'r','LineWidth',1.5); grid on;
xlabel('temps (min)'); ylabel('T (C)'); title('Temperature reacteur (regulee par flash cooler)');
fprintf('Etat final : T=%.1f C, mGyp=%.0f kg, sulfate libre approx=%.2f %%\n',...
        z(end,6), z(end,3), 100*z(end,4)/(z(end,5)+z(end,4)));

%% ---------------------------------------------------------------------
%% 8) OPTIMISATION DES VARIABLES OPERATOIRES (max rendement)
%%    Variables : S = sulfate libre (%), L = ratio eau de lavage (-)
%%    eta = recoveryModel(S,L)  (modele algebrique illustratif, a calibrer)
%% ---------------------------------------------------------------------
fprintf('\n--- 8. OPTIMISATION OPERATOIRE (max eta) ---\n');
objfun = @(x) -recoveryModel(x(1),x(2),P);     % maximiser eta => minimiser -eta
lb=[1.0 1.0]; ub=[3.5 4.0]; x0=[2.0 2.0];
useToolbox = exist('fmincon','file')==2;
if useToolbox
    o=optimoptions('fmincon','Display','off');
    [xopt,fval]=fmincon(objfun,x0,[],[],[],[],lb,ub,[],o);
else                                            % repli : recherche par grille
    Sg=linspace(lb(1),ub(1),60); Lg=linspace(lb(2),ub(2),60);
    best=-inf; xopt=x0;
    for a=Sg, for b=Lg
        e=recoveryModel(a,b,P); if e>best, best=e; xopt=[a b]; end
    end, end
    fval=-best;
end
fprintf('Optimum : sulfate libre S=%.2f %%, ratio lavage L=%.2f\n',xopt(1),xopt(2));
fprintf('Rendement optimise eta = %.2f %% (vs base %.1f %%)\n',-fval*100,P.eta0*100);
% Carte de reponse eta(S,L)
[Sg,Lg]=meshgrid(linspace(lb(1),ub(1),40),linspace(lb(2),ub(2),40));
Eg=arrayfun(@(a,b) recoveryModel(a,b,P), Sg,Lg);
figure('Name','SurfaceReponse','Color','w');
contourf(Sg,Lg,Eg*100,20); colorbar; hold on; plot(xopt(1),xopt(2),'rp','MarkerSize',14,'MarkerFaceColor','r');
xlabel('sulfate libre S (%)'); ylabel('ratio eau de lavage L (-)');
title('Rendement \eta(S,L) (%) - modele illustratif a calibrer');

fprintf('\n===== FIN =====  (figures generees ; calibrer les modeles 7-8 sur donnees reelles)\n');

%% =====================================================================
%%                       FONCTIONS LOCALES
%% =====================================================================
function R = steadyState(P)
% Bilan matiere/energie analytique en regime permanent.
    R.H2SO4pur = P.Q_acid*P.rho_acid*P.w_acid;         % t/h
    R.P2O5in   = P.F_rock*P.xP;                        % t/h
    R.CaOin    = P.F_rock*P.xCa;                       % t/h
    R.CO2in    = P.F_rock*P.xCO2;                      % t/h
    R.nCaO     = R.CaOin*1000/P.M.CaO;                 % kmol/h
    R.gypse    = R.nCaO*P.M.Gypse/1000;                % t/h (gypse sec)
    R.H2SO4st  = R.nCaO*P.M.H2SO4/1000;                % t/h stoechio.
    R.excess   = (R.H2SO4pur-R.H2SO4st)/R.H2SO4st*100; % %
    R.eta      = P.eta0;
    R.P2O5rec  = R.eta*R.P2O5in;                       % t/h
    R.lossP    = R.P2O5in - R.P2O5rec;                 % t/h
    R.H3PO4    = R.P2O5rec*(2*P.M.H3PO4)/P.M.P2O5;     % t/h (100%)
    R.acidsol  = R.P2O5rec/P.wacid_prod;               % t/h solution
    R.gyp_wet  = R.gypse/(1-P.hum);                    % t/h gateau humide
    % --- energie ---
    nH2SO4     = R.H2SO4pur*1000/P.M.H2SO4;            % kmol/h
    R.Qr       = R.nCaO*P.dHr/3600;                    % MW
    R.Qd       = nH2SO4*P.dHdil/3600;                  % MW
    R.Qtot     = R.Qr + R.Qd;                          % MW
    R.evap     = R.Qtot*1000/P.lambda*3.6;             % t/h eau evaporee
    R.duty_cond= P.Qsw*1000/3600*P.Cp_sw*(P.Tsw_out-P.Tsw_in)/1000; % MW
    % --- fermeture masse (eau fraiche = variable de fermeture) ---
    inKnown    = P.F_rock + R.H2SO4pur;
    outAll     = R.acidsol + R.gyp_wet + R.CO2in + R.evap;
    R.water_make = outAll - inKnown;                   % t/h eau fraiche
    R.close    = (inKnown + R.water_make) - outAll;    % ~0 par construction
end

function dz = attackODE(t,z,P,u)
% Modele dynamique lumped du reacteur d'attaque + flash cooler.
% Etats : z=[mP; mCa; mGyp; mH2SO4; mW; T]  (kg,kg,kg,kg,kg,C)
% ILLUSTRATIF - cinetique simplifiee, a calibrer sur donnees reelles.
    mP=z(1); mCa=z(2); mGyp=z(3); mA=max(z(4),0); mW=max(z(5),1); T=z(6);
    % --- cinetique d'attaque (kg CaO / s) ---
    k0=2.0e6; Ea=45e3; Rgas=8.314; TK=T+273.15;
    Cacid = mA/(mW+mA);                        % fraction massique acide libre
    Km=0.03;                                    % saturation
    rate_Ca = k0*exp(-Ea/(Rgas*TK)) * mCa * Cacid/(Cacid+Km); % kg CaO/s (approx)
    rate_Ca = min(rate_Ca, mCa/10);             % borne physique
    % stoechiometrie massique (par kg CaO) :
    Mg = P.M.Gypse/P.M.CaO;                      % kg gypse / kg CaO
    Ma = P.M.H2SO4/P.M.CaO;                      % kg H2SO4 / kg CaO
    MpCa = P.xP/P.xCa;                           % kg P2O5 libere / kg CaO (roche)
    % --- feeds (kg/s) ---
    Fca_in = u.Frock*P.xCa;                      % CaO entrant
    FP_in  = u.Frock*P.xP;                       % P2O5 entrant
    FA_in  = u.Facid;                            % H2SO4 entrant
    FW_in  = u.Frock*(1-P.phi_sol)/P.phi_sol;    % eau associee a la pulpe
    % --- sorties (soutirage bouillie proportionnel, tau ~ 30 min) ---
    tau=1800;
    out = @(m) m/tau;
    % --- energie ---
    dHr_s = P.dHr*1000/P.M.CaO;                  % kJ/kg CaO
    Qgen  = rate_Ca*dHr_s;                       % kJ/s = kW
    % flash cooler : evacue pour tenir la consigne (P-control simple)
    Kc=50;                                        % gain kW/K
    Qflash= max(0, Kc*(T-u.Tset)*100 + Qgen*0.9); % kW retire
    mtot  = mP+mCa+mGyp+mA+mW; Cp=3.0;           % kJ/kg.K bouillie
    % --- equations de bilan ---
    dmP   = FP_in - out(mP);                                   % P2O5 en solution
    dmCa  = Fca_in - rate_Ca - out(mCa);                       % CaO non reagi
    dmGyp = rate_Ca*Mg - out(mGyp);                            % gypse forme
    dmA   = FA_in - rate_Ca*Ma - out(mA);                      % H2SO4 libre
    dmW   = FW_in - (Qflash/P.lambda) - out(mW);              % eau (evap flash)
    dT    = (Qgen - Qflash + FA_in*P.dHdil*1000/P.M.H2SO4) / (mtot*Cp); % C/s
    dz    = [dmP; dmCa; dmGyp; dmA; dmW; dT];
end

function eta = recoveryModel(S,L,P)
% Modele algebrique du rendement en fonction du sulfate libre S (%)
% et du ratio d'eau de lavage L (-).  ILLUSTRATIF - a calibrer.
%   - pertes solubles : diminuent avec le lavage L
%   - pertes co-cristallisees : minimales a S* (optimum ~2.5%)
    eps_sol0=0.020; alpha=0.6;      % pertes solubles de base / effet lavage
    eps_cc0 =0.012; beta=0.004; Sopt=2.5;   % co-cristallisation
    eps_insol=0.008;                % non attaque (fixe)
    eps_sol = eps_sol0*exp(-alpha*(L-1));
    eps_cc  = eps_cc0*(1+beta*100*(S-Sopt)^2);
    eta = 1 - eps_sol - eps_cc - eps_insol;
    eta = max(0.90, min(0.995, eta));
end

function y = triangular(a,c,b,N)
% Tirage triangulaire (a=min, c=mode, b=max), N echantillons.
    u=rand(N,1); Fc=(c-a)/(b-a); y=zeros(N,1);
    idx=u<Fc;  y(idx)=a+sqrt(u(idx)*(b-a)*(c-a));
    y(~idx)=b-sqrt((1-u(~idx))*(b-a)*(b-c));
end

function p = prctile(x,q)
% Percentile simple (si Statistics Toolbox absent).
    x=sort(x(:)); n=numel(x); if n==0, p=NaN; return; end
    r=q/100*(n-1)+1; lo=floor(r); hi=ceil(r);
    if lo==hi, p=x(lo); else, p=x(lo)+(r-lo)*(x(hi)-x(lo)); end
end
