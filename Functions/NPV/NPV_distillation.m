function [D_Col,H_Col,V_Col,Cbm]=NPV_distillation(P_Col,S_Col,...
    Ohm,Rho_l,Rho_v,m_Dist,m_Top)
%% Disitillatoin Column Sizing
% 
% Take operating pressure, number of stages and dew temperature of 
% distillate and calculate coulmn diameter, height, volume.
% Dew temperature is calculated from outside and input data.
% 
% P_Col : Design column pressure (bar)
% S_Col : Distillation column stages number (-)

% 
% Reference : B.Reinhard, Distillation Engineering(1979) 
%
%% Column Diameter Calculation from Paper

% Reflux ratio (-)
%R_r=n_TopL/n_Dist;

% Average velocity of the vapors in the column (m/s)
%v_Col_v=0.761*sqrt(1/P_Col); 

% Coulmn diameter (m)
%D_Col=sqrt((4/(pi*v_Col_v))*(22.2*n_Dist*(R_r+1)*(DewT_Dist/273)*...
    %(1/P_Col)*(1/3600)));

% Heigth of column (m)
% Assumption : Tray Spacing is 18in(0.4572 m), efficiency is 0.80
% If you want other value, Change the constant to the tray spacing
% length (in Si units) and Tray efficiency
H_Col=0.4572*(S_Col/0.80)+4.72; %[m]

%% Column Diameter Calcaultion from Textbook

F_lv=(m_Top/m_Dist)*sqrt(Rho_v/Rho_l);
%Tray Spacing (S):
%Tray spacing is the distance between two trays. 
%Generally tray spacing ranges from 8 to 36 inches (200 mm to 900 mm).
%(0.666 ft to 3 ft)
%Prime factor in setting tray spacing is the economic trade-off between 
%column height and column diameter. Most columns have 600 mm tray spacing. 
%Cryogenic columns have tray spacing of 200-300 mm. 
%http://seperationtechnology.com/distillation-column-tray-selection-1/
Space=1.5;% [ft]
CSB=0.04232+0.1674*Space+(0.0063-0.2686*Space)*F_lv+(0.1448*Space-...
    0.008)*F_lv^2;  %[ft/s]
U_Nf=CSB*sqrt((Rho_l-Rho_v)/Rho_v)*(Ohm/20)^0.2; %[ft/s]
ft2meter = 0.3048;
U_Nf = U_Nf * ft2meter; %[m/s]
D_Col=sqrt((4/pi)*(m_Dist/(0.8*U_Nf*0.8*Rho_v))); %m
% Volume of column (m^3) : Cylinder vessel
V_Col=H_Col*pi*(D_Col/2)^2;

%% Distillation Column Purchase Cost (JeongNam)
CT_power=3.4974+0.4485*log10(V_Col)+0.1074*log10(V_Col)^2;
CT_p=10^CT_power;
FT_P=((P_Col*D_Col)/(2*(850-0.6*P_Col))+0.00315)/0.0063;
FT_M=1;BT1=2.25;BT2=1.82;
FT_BM=BT1+BT2*FT_M*FT_P;
CT_BM=CT_p*FT_BM;



%Tray Purchase Cost
Area_Tr=pi*(D_Col/2)^2;
CTr_power=2.9949+0.4465*log10(Area_Tr)+0.3961*log10(Area_Tr)^2;
CTr_p=10^CTr_power;CTr_BM=CTr_p*S_Col;

C_BM=CT_BM+CTr_BM;

%% Distillation Column Purchase Cost (Jonggeol)
%Tower Purchase Cost (Seider)
% Sandler and Luckiewicz (1987)
P0 = (P_Col- 101325/100000) * 14.5038 ; %bar to psig
if P0 < 10
    Pd = 10; %psig
elseif P0 < 1000
    Pd = exp(0.60608 + 0.91615*log(P0) + 0.0015655*log(P0)^2);
else
    Pd = P0*1.1;
end

% meter to inches
meter2inches = 39.3701;
H_Col_in = H_Col * meter2inches;
D_Col_in = D_Col * meter2inches;



% ASME pressure vessel code formula:
% assumption 1) Maximum allowable stress (psi) = 15,000
% assumption 2) fractional weld efficiency = 0.85
% minimum thickness

if H_Col_in/12 <1/4
    tmin = 1/4; %in
elseif H_Col_in/12 < 6
    tmin = 5/16; %in
elseif H_Col_in/12 <10
    tmin = 7/16; %in
else
    tmin = 1/2; %in
end
tp = max(tmin, Pd*D_Col_in/(2*15000*0.85 - 1.2*Pd)); %[inch]
tw = max(tmin, 0.22*(D_Col_in+ 2.5 + 18)*(H_Col_in*0.0833333)^2/(15000*(D_Col_in + 2.5)^2));
tv = (tp+tw)/2;
ts = tv +0.125; %corrosion allowance

W = pi * (D_Col_in + ts) * (H_Col_in + 0.8*D_Col_in) * ts * 0.284 ;  % density for steel plate [lb]

if W < 2500000 && W> 9000
    Cv = exp(7.2756 + 0.18255*log(W)+0.02297*log(W)^2);
else
    Cv = exp(7.2756 + 0.18255*log(W)+0.02297*log(W)^2);
%     disp('W is out of range (distillation)')
end

if D_Col_in < 24*12 && D_Col_in > 3*12 && H_Col_in < 170 * 12 && H_Col_in > 27 * 12
    Cpl = 300.9 * (D_Col_in/12)^0.63316 * (H_Col_in/12)^0.80161;
else
    Cpl = 300.9 * (D_Col_in/12)^0.63316 * (H_Col_in/12)^0.80161;
%        disp('Cpl is out of range (distillation)')
end

% Purchase cost for CE index of 550 for just the tower

Ccolumn = (550/500) * (Cv + Cpl);

% base cost for sieve tray
Cbt = 468*exp(0.1739*D_Col_in/12); %[$/tray]

Ctray = S_Col*1 * 1 * 1 * Cbt * 550/500;

C_totalPurchaseCost = Ccolumn + Ctray;

Fbm = 4.3; % bare-module factor for distillation column is 4.3

Cbm = C_totalPurchaseCost * Fbm; %$


    




    







