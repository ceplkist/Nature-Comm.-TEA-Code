function [RESULT] = cash_flow(RESULT,input, COST, Efficiency, CurrentDensity, potential, components, h)
option.COSTSHEET=false;
option.FIGURE = true;

%% Results Update for Techno-economic analysis
% Recalculation for electrolyzer output

num_unit = size(RESULT.UNIT,1);
load materials.mat
[RESULT.ProductionRate,RESULT.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);

%% TOTAL SALES (S)
S(1) = dot(RESULT.OUTPUT.CathodeProduct.massFlow, COST.product.cathode) * 3600 * COST.utility.operating_hour; %TOTAL SALES for cathode products kg/s * $/kg  = $/s , $/s * 3600 * 8000, 8000시간 운전
S(2) = dot(RESULT.OUTPUT.AnodeProduct.massFlow, COST.product.anode) * 3600 * COST.utility.operating_hour; %TOTAL SALES for anode products kg/s * $/kg  = $/s , $/s * 3600 * 8000, 8000시간 운전

temp = 0;
if length(components.cathode) ==2
    if strcmp(char(materials.phase(components.cathode(2))),'g')
        temp = RESULT.OUTPUT.CathodeProduct.massFlow(2) * COST.product.cathode(2) * 3600 * COST.utility.operating_hour;
    end
end
S_gas = (RESULT.OUTPUT.CathodeProduct.massFlow(1) * COST.product.cathode(1) * 3600 * COST.utility.operating_hour + ...
    RESULT.OUTPUT.AnodeProduct.massFlow(1) * COST.product.anode(1) * 3600 * COST.utility.operating_hour + ...
    temp); % for Working Capital 가스 product에 Sales
%% Components of Total Capital Investment (TCI)
% Bare-module cost can be calculated by Bare-Module Factors of Guthrie
% (1974) pg 549 of Seider book.
%Total bare-module costs for fabricated equipment  + Total bar-module costs for process machinery + Total bare-module costs for spares + Total bare-module costs for storage and surge tanks
C_EQP        = sum(RESULT.CapitalCosts.electrolyzer) + ... % electrolyzer
    sum(RESULT.CapitalCosts.flash) + ...        % flash
    sum(RESULT.CapitalCosts.compressor) + ...   % compressor
    sum(RESULT.CapitalCosts.distillation) + ... % distillation
    sum(RESULT.CapitalCosts.extraction) + ...   % extraction
    sum(RESULT.CapitalCosts.PSA) + ...           % pressure swing adsorption
    sum(RESULT.CapitalCosts.heater);            % heater
% C_catalyst   = 5000; %Total cost for initial catayst charges + electrolyte
C_comp       = 20000; %Total bare-module costs for computers and software,
C_TBM        = C_EQP+C_comp; %+C_catalyst %Total bare-module investment, TBM

C_site       = 0.1*C_TBM; %Cost of site preparation (10-20% C_TBM for new plant, 4-6% for existing integrated complex)
C_serv       = 0; %Cost of service facilities
C_alloc      = 0; %Allocated costs for utility plants and related facilities
C_DPI        = C_TBM+C_site+C_serv+C_alloc; %Total of direct permanent investment, DPI

C_cont       = (0.15)*C_DPI; %Cost of contingencies and contractor's fee (Guthrie add 3%, total 18% but 15% is common)
C_TDC        = C_DPI+C_cont; %Total depreciable captial, TDC

C_land       = 0.02*C_TDC; %Cost of land
C_royal      = 0; % If there is loyalty then = 0.02*C_TDC and 0.03*sum(S) annually; %Cost of royalties
C_startup    = 0.02*C_TDC; %Cost of Plant startup
C_TPI        = C_TDC+C_land+C_royal+C_startup; %Total permanent investment, TPI

% Working Capital and Total Capital Investment will be calculated after
% production cost

%% Total Production Cost (C), annual base
% Feedstocks
C_feed(1) = COST.feed.CO2*RESULT.FEED.CO2.massFlow*3600*COST.utility.operating_hour; %CO2 $/tonCO2 *kg/s *10^-3 -> $/s *3600 * 8000
if length(components.anode) == 2
    C_feed(2) = COST.feed.CH*RESULT.FEED.CH.massFlow*3600*COST.utility.operating_hour; %organic chemicals
else
    C_feed(2) = 0;% no organic raw materials
end
C_feed(3) = COST.feed.EL*RESULT.FEED.EL.massFlow*3600*COST.utility.operating_hour; %water

% Utilites
C_util(1) = sum(RESULT.OperatingCost.STEAM); %Steam
C_util(2) = sum(RESULT.OperatingCost.ELECTRICITY); %electricity
C_util(3) = sum(RESULT.OperatingCost.WWT); %wastewater treatment
C_util(4) = sum(RESULT.OperatingCost.REFRIGERATION); %refrigeration
C_util(5) = sum(RESULT.OperatingCost.CO2_Capture); %CO2 capture for SEP:C:GG


% Operations (labor-related) (O)
C_O(1) = COST.utility.DWandB * COST.utility.workers * COST.utility.operating_hour; % Direct wages and benefits (DW&B) 
C_O(2) = 0.15*C_O(1); % Direct salaries and benefits	15% of DW&B
C_O(3) = 0.06*C_O(2); % Operating supplies and services		6% of DW&B
C_O(4) = COST.utility.TechAssist2Manufacturing * COST.utility.workers / COST.utility.shift; %Technical assistance to manufacturing
C_O(5) = COST.utility.ControlLab * COST.utility.workers / COST.utility.shift; %Control laboratory

% Maintenance (M)
C_M(1) = 0.035*C_TDC; %Wages and benefits (MW&B) Fluid handling process	3.5% of C_{TDC}
C_M(2) = 0.25*C_M(1); %Salaries and benefits	25% of MW&B
C_M(3) = 1.00*C_M(1); %Materials and services	100% of MW&B
C_M(4) = 0.05*C_M(1); %Maintenance overhead		5% of MW&B


% Operating overhead
MOSWB = C_O(1)+C_O(2)+C_M(1)+C_M(2); %M&O-SW&B = DW&B + Direct salaries and benefits + MW&B + Maintenance salaries and benefits
C_OH(1) = 0.071*MOSWB; %General plant overhead		7.1% of M&O-SW&B
C_OH(2) = 0.024*MOSWB; %Mechanical department services		2.4% of M&O-SW&B
C_OH(3) = 0.059*MOSWB; %Emplyee relations department		5.9% of M&O-SW&B
C_OH(4) = 0.074*MOSWB; %Business services		7.4% of M&O-SW&B

% Property taxes and insurance			2% of C_{TDC}
C_prop = 0.02*C_TDC;

% Depreciation
C_D(1) = 0.08*(C_TDC-1.18*C_alloc); %Direct plant		8% of (C_{TDC}-1.18C_{alloc})
C_D(2) = 0.06*1.18*C_alloc; %Allocated plant		6% of 1.18C_{alloc}
C_D(3) = 0; %Rental fees (Office and lab space)
C_D(4) = 0; %Licensing fees

% COST OF MANUFACTURES (COM) sum of above (1)direct manufacturing cost(feedstocks, utilites, O, M); (2) operating overhead; and  (3) fixed costs(property taxes, insurance, and depreciation)

COM = sum([C_feed C_util C_O C_M C_OH C_prop C_D]);

% GENERAL EXPENSES
GE(1) = 0.03*sum(S)+0.01*sum(S); %Selling (or transfer) expense		3% (1%) of sales
GE(2) = 0.048*sum(S); %Direct research		4.8% of sales
GE(3) = 0.005*sum(S); %Allocated research		0.5% of sales
GE(4) = 0.02*sum(S); %Administrative expense		2.0% of sales
GE(5) = 0.0125*sum(S); %Management incentive compensation		1.25% of sales

%% CASH FLOWS

CF_C_TDC = zeros(1, COST.plant_life);
CF_C_WC  = zeros(1, COST.plant_life);
CF_C_land = zeros(1, COST.plant_life);
CF_C_startup = zeros(1, COST.plant_life);
CF_C_royal = zeros(1, COST.plant_life);
CF_S_equip = zeros(1, COST.plant_life);
CF_C_D   = zeros(1, COST.plant_life);
CF_C     = zeros(1, COST.plant_life);
CF_NetEarnings  =  zeros(1, COST.plant_life);
CF_DCF = zeros(1, COST.plant_life);
CF_PV = zeros(1, COST.plant_life);
CF_NPV = zeros(1, COST.plant_life);


for i=1:COST.plant_life
    
    
    if mod(i-COST.construction_period-1,COST.catalyst.year) == 0
        % for replacement interval of major components of electrolyzer
        % TOTAL PRODUCTION COST (C)
        ReferredDATA = cell2table({'Technical Parameters',0,0,0,0;'Production Equipment Availability Factor (%)',97,97,97,97;'Plant Design Capacity (kg of H2/day)',1500,1500,50000,50000;'Single Unit Size (kg/day)',500,750,500,750;'System Energy (kW)',3413,3144,113125,104583;'System H2 Output pressure (psi)',450,1000,450,1000;'System O2 Output pressure (psi)',14,14,14,14;'Direct Capital Costs',0,0,0,0;'Basis Year for production system costs',2012,2012,2012,2012;'Uninstalled Cost - ($/kW) (with suggested subsystem breakdown, further breakdown desirable if available)',940,450,900,400;'stacks (%)',41,38,47,37;'BoP ToTal (%)',59,62,53,63;'Hydrogen Gas Management System-Cathode system side (%)',10,6,9,1;'Oxygen Gas Management System-Anode system side (%)',5,2,3,1;'Water Reacant Delivery Management System (%)',6,5,5,1;'Thermal Management System (%)',5,5,5,7;'Power Electronics (%)',20,26,21,44;'Controls & Sensors (%)',3,6,2,1;'Mechanical Balance of Plant-ss plumbing/copper cabling/Dryer valves…  (%)',5,5,5,2;'Item Breakdown - Other (%)',1,2,1,3;'Item Breakdown-Assembly Labor (%)',4,5,2,3;'Installation factor (a multiplier on uninstalled cap cost)',1.12000000000000,1.10000000000000,1.12000000000000,1.10000000000000;'Indirect Capital Costs',0,0,0,0;'Site Preparation ($) (may change to construction costs)',18.8500000000000,18.8500000000000,2,2;'Engineering & Design ($ or %)',50000,50000,8,8;'Project contingency ($)',15,15,15,15;'Up-Front Permitting Costs ($ or %) (legal and contractors fees included here)',30000,30000,15,15;'Replacement Schedule',0,0,0,0;'Replacement Interval of major components (yrs)',7,10,7,10;'Replacement cost of major components (% of installed capital)',15,12,15,12;'O&M Costs-Fixed',0,0,0,0;'Licensing, Permits and Fees ($/year)',1000,1000,0,0;'Yearly maintenance costs ($/yr) (Please specify in notes types of activities) (%)',3.20000000000000,2.80000000000000,3,3;'O&M Costs-Variable',0,0,0,0;'Total plant staff (total FTE''s)',0,0,10,10;'Feedstocks and Other Materials',0,0,0,0;'System Electricity Usage (kWh/kg H2)',54.6000000000000,50.3000000000000,54.3000000000000,50.2000000000000;'Stack electrical usage',49.2000000000000,50.3000000000000,54.3000000000000,50.2000000000000;'BOP electrical usage',5.40000000000000,46.7000000000000,49.2000000000000,46.7000000000000;'Minimum Process water usage (gal/kg H2)',4.76000000000000,3.98000000000000,4.76000000000000,3.98000000000000;'Cooling water usage (gal/kg H2)',0,0,0,0;'Compressed Inert Gas (Nm3/kg H2)',0,0,0,0;'cell potential for PEM electrolyzer',1.75000000000000,1.65000000000000,1.75000000000000,1.65000000000000;'current density for PEM electrolyzer',1500,1600,1500,1600}, 'VariableNames', {'description','forecourt_current','forecourt_future','central_current','central_future'});
        
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
        
        C = COM+sum(GE) + RESULT.CapitalCosts.electrolyzer*electrolyzerData(30)/100;
    else
        % for normal operation
        % TOTAL PRODUCTION COST (C)
        C = COM+sum(GE);
    end
    
    % Working capital and total capital investment
    C_WC         = 0.0833*COM+0.0192*(sum(S)-S_gas)+0.0833*sum(S)-0.0833*sum(C_feed); %Working captital = cash reserves + inventory + accounts reveivable - accounts payable
    C_TCI        = C_TPI+C_WC; %Total captital investment, TCI
    
    % Under construction
    if i<=COST.construction_period
        CF_C_TDC(i) = -C_TDC/COST.construction_period;
        if i==COST.construction_period
            CF_C_WC(i) = -C_WC;
        end
    end
    
    % Depreciation with MACRS
    if i==COST.construction_period
        CF_C_D(i+1:i+length(COST.MACRS)) = sum(C_D)*COST.MACRS;
    end
    
    % After construction
    if i>=COST.construction_period+1
        CF_C(i) = C - sum(C_D); % Cost excluded Depreciation cost
        CF_NetEarnings(i) = (sum(S) - CF_C(i) - CF_C_D(i)).*(1-COST.tax);
    end
    
    % End of the plant
    if i == COST.plant_life
        CF_C_WC(i) = +C_WC;
    end
    
end

% Discounted Cash Flow
for i=1:COST.plant_life
    CF_DCF(i) = (CF_NetEarnings(i)+CF_C_D(i)) + CF_C_TDC(i) + CF_C_WC(i);
    CF_PV(i)  = CF_DCF(i)/(1+COST.irate)^i;
    CF_NPV(i) = sum(CF_PV(1:i));
end

% Write to the COSTSHEET (option.COSTSHEET = true)
if option.COSTSHEET
    filename = 'COSTSHEET.xlsx';
    RESULT = [CF_C_TDC' CF_C_WC' CF_C_land' CF_C_startup' CF_C_royal' CF_S_equip' ...
        CF_C_D' CF_C' sum(S)*ones(COST.plant_life,1) CF_NetEarnings' CF_DCF' CF_PV' CF_NPV'];
    sheet = 3;
    xlRange = 'C3';
    xlswrite(filename,RESULT,sheet,xlRange)
end

if option.FIGURE
figure(10)
    plot(CF_DCF,'linewidth',1.2,'Marker','o');
    hold on
    plot(CF_PV,'linewidth',1.2,'Marker','o');
    plot(CF_NPV,'linewidth',1.2,'Marker','o');
    legend({'DCF','PV','NPV'})
    ylabel('Metrics ($)')
    xlabel('Time (year)')
    set(gca,'linewidth',1,'layer','top')
    axis square
    grid on
    grid minor
end
CASHFLOW = [CF_C_TDC' CF_C_WC' CF_C_land' CF_C_startup' CF_C_royal' CF_S_equip' ...
    CF_C_D' CF_C' sum(S)*ones(COST.plant_life,1) CF_NetEarnings' CF_DCF' CF_PV' CF_NPV'];
RESULT.NPV = (CF_NPV(end));
RESULT.CASHFLOW = CASHFLOW;
RESULT.EconomicData.C_EQP = C_EQP;
RESULT.EconomicData.C_comp = C_comp;
RESULT.EconomicData.C_EQP = C_EQP;
RESULT.EconomicData.C_site = C_site;
RESULT.EconomicData.C_serv = C_serv;
RESULT.EconomicData.C_alloc = C_alloc;
RESULT.EconomicData.C_DPI = C_DPI;
RESULT.EconomicData.C_cont = C_cont;
RESULT.EconomicData.C_TDC = C_TDC;
RESULT.EconomicData.C_land  = C_land ;
RESULT.EconomicData.C_royal = C_royal;
RESULT.EconomicData.C_startup = C_startup;
RESULT.EconomicData.C_TPI = C_TPI;
RESULT.EconomicData.C_feed = C_feed;
RESULT.EconomicData.C_util = C_util;
RESULT.EconomicData.C_O = C_O;
RESULT.EconomicData.C_M = C_M;
RESULT.EconomicData.C_OH = C_OH;
RESULT.EconomicData.C_prop = C_prop;
RESULT.EconomicData.C_D = C_D;
RESULT.EconomicData.C_COM = COM;
RESULT.EconomicData.GE = GE;
RESULT.EconomicData.C = C;
RESULT.EconomicData.C_WC = C_WC;
RESULT.EconomicData.C_TCI = C_TCI;
RESULT.EconomicData.S = S;
RESULT.EconomicData.S_gas = S_gas;

