function [D_Col,H_Col,V_Col,Cbm]=NPV_PSA(P_Col,V_activecarbon)
%% PSA system purchase cost
% Volume of active carbon input is m3 we need ft3
mtoft = 3.28084;
m3toft3 = 35.3147;
V_activecarbon = V_activecarbon * m3toft3;
%% Purchase cost of active carbon
C_P_AC = 30*V_activecarbon; % [$] f.o.b. purchase cost equation (reference Seider, Table 22.32)
C_BM_AC  = C_P_AC * 4.3; % Bare Module factor = 4.3 for adsorbers.

%% Purchase cost of pressured vessel
% reference: Di Marcoberardino, G., Vitali, D., Spinelli, F., Binotti, M., & Manzolini, G. (2018). Green hydrogen production from raw biogas: A techno-economic investigation of conventional processes using pressure swing adsorption unit. Processes, 6(3), 19-41.
% Parameter Unit Value
% Column diameter m 0.38
D_Col = 0.38*mtoft; %[ft]
H_Col = V_activecarbon/(pi*(D_Col/2)^2) +  3 + 3; %[ft] 촉매 부피 위 아래 3 ft씩 더 함
V_Col = pi*(D_Col/2)^2 * H_Col; %[ft3]

%Tower Purchase Cost
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

% feet to inch
H_Col_in = H_Col * 12;
D_Col_in = D_Col * 12;



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
C_totalPurchaseCost = Ccolumn;
Fbm = 4.3; % bare-module factor for distillation column is 4.3
Cbm = C_totalPurchaseCost * Fbm; %$





