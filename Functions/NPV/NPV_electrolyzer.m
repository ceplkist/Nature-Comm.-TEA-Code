function [CapitalCosts, ReferredDATA] = NPV_electrolyzerData(RESULT,input, COST, CurrentDensity, potential)
% Based on Hydrogen Pathways Analysis for Polymer Electrolyte Membrane (PEM) Electrolysis
% 2014 DOE Hydrogen and Fuel Cells Program and Vehicle Technologies Office Annual Merit Review and Peer Evaluation Meeting
% Strategic Analysis Inc.
% Whitney G. Colella (Presenter)
% Brian D. James (PI)
% Jennie M. Moton
% June 16-20, 2014
%
% RESULT is from simulation results
% type = 1. Forecourt Current / 2. Forecourt Future / 3. Central Current /
% 4. Central Future
%
% OUTPUT
% CapitalCosts
% ReferredDATA
%% Refered data
ReferredDATA = cell2table({'Technical Parameters',0,0,0,0;'Production Equipment Availability Factor (%)',97,97,97,97;'Plant Design Capacity (kg of H2/day)',1500,1500,50000,50000;'Single Unit Size (kg/day)',500,750,500,750;'System Energy (kW)',3413,3144,113125,104583;'System H2 Output pressure (psi)',450,1000,450,1000;'System O2 Output pressure (psi)',14,14,14,14;'Direct Capital Costs',0,0,0,0;'Basis Year for production system costs',2012,2012,2012,2012;'Uninstalled Cost - ($/kW) (with suggested subsystem breakdown, further breakdown desirable if available)',940,450,900,400;'stacks (%)',41,38,47,37;'BoP ToTal (%)',59,62,53,63;'Hydrogen Gas Management System-Cathode system side (%)',10,6,9,1;'Oxygen Gas Management System-Anode system side (%)',5,2,3,1;'Water Reacant Delivery Management System (%)',6,5,5,1;'Thermal Management System (%)',5,5,5,7;'Power Electronics (%)',20,26,21,44;'Controls & Sensors (%)',3,6,2,1;'Mechanical Balance of Plant-ss plumbing/copper cabling/Dryer valves¡¦  (%)',5,5,5,2;'Item Breakdown - Other (%)',1,2,1,3;'Item Breakdown-Assembly Labor (%)',4,5,2,3;'Installation factor (a multiplier on uninstalled cap cost)',1.12000000000000,1.10000000000000,1.12000000000000,1.10000000000000;'Indirect Capital Costs',0,0,0,0;'Site Preparation ($) (may change to construction costs)',18.8500000000000,18.8500000000000,2,2;'Engineering & Design ($ or %)',50000,50000,8,8;'Project contingency ($)',15,15,15,15;'Up-Front Permitting Costs ($ or %) (legal and contractors fees included here)',30000,30000,15,15;'Replacement Schedule',0,0,0,0;'Replacement Interval of major components (yrs)',7,10,7,10;'Replacement cost of major components (% of installed capital)',15,12,15,12;'O&M Costs-Fixed',0,0,0,0;'Licensing, Permits and Fees ($/year)',1000,1000,0,0;'Yearly maintenance costs ($/yr) (Please specify in notes types of activities) (%)',3.20000000000000,2.80000000000000,3,3;'O&M Costs-Variable',0,0,0,0;'Total plant staff (total FTE''s)',0,0,10,10;'Feedstocks and Other Materials',0,0,0,0;'System Electricity Usage (kWh/kg H2)',54.6000000000000,50.3000000000000,54.3000000000000,50.2000000000000;'Stack electrical usage',49.2000000000000,50.3000000000000,54.3000000000000,50.2000000000000;'BOP electrical usage',5.40000000000000,46.7000000000000,49.2000000000000,46.7000000000000;'Minimum Process water usage (gal/kg H2)',4.76000000000000,3.98000000000000,4.76000000000000,3.98000000000000;'Cooling water usage (gal/kg H2)',0,0,0,0;'Compressed Inert Gas (Nm3/kg H2)',0,0,0,0;'cell potential for PEM electrolyzer',1.75000000000000,1.65000000000000,1.75000000000000,1.65000000000000;'current density for PEM electrolyzer',1500,1600,1500,1600}, 'VariableNames', {'description','forecourt_current','forecourt_future','central_current','central_future'});


switch COST.type
    case 1
        electrolyzerData = ReferredDATA.forecourt_current;
    case 2
        electrolyzerData = ReferredDATA.forecourt_future;
    case 3
        electrolyzerData = ReferredDATA.central_current;
    case 4
        electrolyzerData = ReferredDATA.central_future;
end
% Excel version: \Electrolyzer_reference.xlsx

%% Calculate Capital Cost ($)
% Direct Capital Costs per Area for reference data
UninstalledCost_stack = electrolyzerData(10)*electrolyzerData(11)/100;
UninstalledCost_BoP   = electrolyzerData(10)*electrolyzerData(12)/100;
UninstalledCost_catmem = UninstalledCost_stack * 0.6;  % cost of membrane, catalyst, anode, and cathode make up ~6-%

DirectCapitalCosts = electrolyzerData(10)*electrolyzerData(22); % Uninstalled cost * Installation factor [$/kW]
Work = electrolyzerData(43) * electrolyzerData(44) * 10; % potential * current density for reference [W/m2]
RequiredArea = electrolyzerData(5)*1000 / Work ;    % [m2]
DirectCapitalCostsArea = DirectCapitalCosts*Work*10^-3; % [$/m2]

% Direct Capital Costs for our cell
%%% catalysts for reference cell are anode(iridium) / cathode(platinum)
%%% cost from http://www.infomine.com (2019/01/22) $/kg
% COST.metal.Pt = 25500;
% COST.metal.Ir = 46940;
% COST.metal.Al = 1.851;
% COST.metal.Cu = 6.04287;
% COST.metal.Au = 41290;
% COST.metal.Ag = 490;
% COST.metal.Zn = 2.57698;
% COST.metal.Pb = 1.97203;
% COST.metal.Ru = 8550;
% COST.metal.Pd = 43180;
% COST.metal.Ni = 11.61;
% COST.metal.Co = 38.00;
% COST.metal.Mo = 26.00;
%%% membrane for reference cell is Nafion
UninstalledCost_catmem_ours = UninstalledCost_catmem*(COST.catalyst.anode+COST.catalyst.cathode)/...%+COST.membrane)/...
    (COST.metal.Ir + COST.metal.Pt);% + Nafion);
UninstalledCost_stack_ours = UninstalledCost_catmem_ours + UninstalledCost_stack*0.4;
DirectCapitalCosts_ours = (UninstalledCost_stack_ours+UninstalledCost_BoP)*electrolyzerData(22); % Uninstalled cost * Installation factor [$/kW]
Work = electrolyzerData(43) * electrolyzerData(44) * 10; % potential * current density for reference [W/m2]
DirectCapitalCostsArea_ours = DirectCapitalCosts_ours*Work*10^-3; % [$/m2]

CapitalCosts = DirectCapitalCostsArea_ours * RESULT.Area.Cell; % multiply cell area with Direct Capital Costs per Area [$]





