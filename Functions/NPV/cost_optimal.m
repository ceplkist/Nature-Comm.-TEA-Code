% predefined COST information

%% Options
COST.plant_life = 15; % plant life (year)
COST.construction_period = 2; % required period for plant construction (year)
COST.tax = 0; % Income Tax = Federal + State
COST.irate = 0.15; % Norminal Interest Rate
COST.hydrogen = 1.39; % $/kg from SMR
COST.oxygen = 0.032; % $/kg
COST.cathode = materials.price(CathodeCandidate(i));
COST.anode = materials.price(AnodeCandidate(j));
% MACRS (Modified Accelerated Cost Recovery System)
COST.MACRS_3 = [0.3333 0.4445 0.1481 0.0741];
COST.MACRS_5 = [0.2 0.32 0.192 0.1152 0.1152 0.0576];
COST.MACRS_7 = [0.1429 0.2449 0.1749 0.1249 0.0893 0.0892 0.0893 0.0446];
COST.MACRS_10 = [0.1 0.18 0.144 0.1152 0.0922 0.0737 0.0655 0.0655 0.0656 0.0655 0.0328];
COST.MACRS = COST.MACRS_7;
COST.UPF = 1; % scale up factor Aspen -> real process
COST.type =4; % Reactor Type

%% Metal Cost ($/kg)
%%% catalysts for reference cell are anode(iridium) / cathode(platinum)
%%% cost from http://www.infomine.com (2019/01/22) $/kg
COST.metal.Pt = 25500;
COST.metal.Ir = 46940;
COST.metal.Al = 1.851;
COST.metal.Cu = 6.04287;
COST.metal.Au = 41290;
COST.metal.Ag = 490;
COST.metal.Zn = 2.57698;
COST.metal.Pb = 1.97203;
COST.metal.Ru = 8550;
COST.metal.Pd = 43180;
COST.metal.Ni = 11.61;
COST.metal.Co = 38.00;
COST.metal.Mo = 26.00;
%https://www.vanadiumprice.com/
COST.metal.V = 175.267498;

%% Catalyst Cost ($/kg)
eval(['COST.catalyst.cathode = COST.metal.',char(materials.electrode(CathodeCandidate(i))),';']) %$/kg  (to be changed)
eval(['COST.catalyst.anode = COST.metal.',char(materials.electrode(AnodeCandidate(j))),';']) %$/kg  (to be changed)
COST.catalyst.year = 15; % year, replacement interval of major components

%% Feed Cost ($/kg)
%the NETL reference case 10 for monoethanolamine (MEA) (550 MWe subcritical pulverized coal power plant), 
%which is the baseline for most CO2 capture costs, capture cost
COST.feed.CO2 = 0; %$/kg 
try
   COST.feed.CH = materials.price_raw_materials_min{AnodeCandidate(j)}; % $/kg
catch
COST.feed.CH = materials.price_raw_materials_min(AnodeCandidate(j)); % $/kg
end
COST.feed.EL = 0.20/1000*(1-0.0138205) + 1*0.0138205; %$/kg 
% Process water: $0.20/m3, 1000kg/m3
% potassium bicarbonate 0.8 - 1.5 $/kg, mw = 138.205 g/mol, 13.8205 g for
% 0.1 M KHCO3 electrolyte
% https://www.alibaba.com/showroom/potassium-bicarbonate-price.html

%% Utility Cost (reference: Seider, pg 604)
% Busche (1995) with modifications
% Steam
COST.utility.steam450psig = 14.50/1000/1746.83/1000; % $/J 450 psig, 237.778 oC,  1746.83 kJ/kg
COST.utility.steam150psig = 10.50/1000/1993.38/1000; % $/J 150 psig, 185.556 oC,  1993.38 kJ/kg
COST.utility.steam50psig  = 6.60/1000/2121.31/1000;  % $/J  50 psig, 147.778 oC,  2121.31 kJ/kg
% Electricity --> industrial, similar as Korean
COST.utility.electricity = 0.060;       % $/kW-hr
% COST.utility.electricity = 0.10;        % $/kW-hr PV electricity cost from IRENE
% Water (rho = 1000 kg/m3)
COST.utility.pw = 0.20/1000;                 % $/m3 -> $/kg process water = COST.feed.EL
COST.utility.bfw = 0.50/1000;                % $/m3 -> $/kg boiler-feed water
% Refrigeration (1 ton of refrigeration = 12,000 Btu/hr = 3.51685284 kW)
COST.utility.Rn150 = 12.60/10^9;             % $/J -150oF -101.111 oC
COST.utility.Rn90 = 10.30/10^9;              % $/J -90oF  -67.7778
COST.utility.Rn30 = 7.90/10^9;               % $/J -30oF -34.4444
COST.utility.Rp10 = 5.50/10^9;                % $/J 10oF  -12.2222
COST.utility.Rchw = 4.40/10^9;               % $/J - chilled water,40oF 4.44444
COST.utility.cw = 0.020*3.51685284/10^9;    % $/kg->$/J cooling water
% Wastewater treatment
COST.utility.wastewt = 0.33;                 % $/kg organic removed
% Operation
COST.utility.DWandB = 35;                    % $/operator-hr
COST.utility.workers = 10;                   % number of workers
COST.utility.TechAssist2Manufacturing = 60000; % $/(operator/shift)-yr
COST.utility.ControlLab = 65000;             % $/(operator/shift)-yr
COST.utility.shift = 3;                      % shift (assumption)
COST.utility.operating_hour = 8000;          % operating hour (hour/yr)

