function [RESULT] = operatingcost(RESULT,input, COST, Efficiency, CurrentDensity, potential, components, h)
%% Results Update for Techno-economic analysis
% Recalculation for electrolyzer output
num_unit = size(RESULT.UNIT,1);
num_stream = size(RESULT.STREAM,1);
load materials.mat
[RESULT.ProductionRate,RESULT.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);

%% Electricity Cost
% Electrolyzer
WorkperArea = CurrentDensity * potential * 10; % W/m^2
WorkTotal   = WorkperArea * RESULT.Area.Cell/1000 * COST.utility.operating_hour; % kWh / year
OperatingCost.ELECTRICITY = WorkTotal*COST.utility.electricity;                  % $/kW-hr * kWh = $/year

% Compressor ($) for PSA
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Compr')
        Work = RESULT.UNIT.WORK{i}; % [W]
        WorkTotal = Work/1000 * COST.utility.operating_hour; % kWh/year
        OperatingCost.ELECTRICITY = [OperatingCost.ELECTRICITY WorkTotal]; %$/year
    end
end

%% STEAM & Refrigerant Cost
% Distillation Column ($)
OperatingCost.STEAM=[];
OperatingCost.REFRIGERATION=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Distl')
        % Reboiler
        cost_reboiler = 0;
        cost_condensor = 0;
        feedtemp = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\FEED_TRAY_T']).value; %[K]
        bottomtemp = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\BOTTOM_TEMP']).value; %[K]
        heat_duty = abs(RESULT.UNIT.REBDUTY{i}); %  [J/s]
        
        if bottomtemp <=147.778 + 273.15
            cost_reboiler = COST.utility.steam50psig * heat_duty *3600 * COST.utility.operating_hour;
        elseif 147.778 + 273.15<=bottomtemp && bottomtemp <=185.556 + 273.15
            cost_reboiler = COST.utility.steam150psig * heat_duty *3600 * COST.utility.operating_hour;
        elseif 185.556 + 273.15<=bottomtemp && bottomtemp <=237.778 + 273.15
            cost_reboiler = COST.utility.steam450psig * heat_duty *3600 * COST.utility.operating_hour;
        elseif 237.778 + 273.15<=bottomtemp
            cost_reboiler = COST.utility.steam450psig * heat_duty *3600 * COST.utility.operating_hour;
            disp('infeasible temperature (REBOILER) check the steam');
        end
        
        % Condensor
        toptemp  = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\TOP_TEMP']).value; %[K]
        heat_duty = abs(RESULT.UNIT.CONDDUTY{i}); %  [J/s]
        if toptemp <= -101.111 +273.15
            cost_condensor = COST.utility.Rn150 * heat_duty *3600 * COST.utility.operating_hour;
            disp('infeasible temperature (CONDENSOR) check the steam');
        elseif -101.111 + 273.15<=toptemp && toptemp <= -67.7778 + 273.15
            cost_condensor = COST.utility.Rn90 * heat_duty *3600 * COST.utility.operating_hour;
        elseif -67.7778 + 273.15<=toptemp && toptemp <= -34.4444 + 273.15
            cost_condensor = COST.utility.Rn30 * heat_duty *3600 * COST.utility.operating_hour;
        elseif -34.4444 + 273.15<=toptemp && toptemp <= -12.2222 + 273.15
            cost_condensor = COST.utility.Rp10 * heat_duty *3600 * COST.utility.operating_hour;
        elseif -12.2222 + 273.15<=toptemp && toptemp <= 4.4444 + 273.15
            cost_condensor = COST.utility.Rchw * heat_duty *3600 * COST.utility.operating_hour;
        elseif 4.444 + 273.15<=toptemp && toptemp <= 25 + 273.15
            cost_condensor = COST.utility.cw * heat_duty *3600 * COST.utility.operating_hour;
        elseif 25 + 273.15<=toptemp
            cost_condensor = COST.utility.steam50psig * heat_duty *3600 * COST.utility.operating_hour;
        end
        % cost
        OperatingCost.STEAM=[OperatingCost.STEAM cost_reboiler];
        OperatingCost.REFRIGERATION=[OperatingCost.REFRIGERATION cost_condensor];
    end
end

% Heater ($)
% U값이 너무 크게 되어 있는듯? 확인 하고 수정 필요.
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Heater') &&...
            ~strcmp(RESULT.UNIT.NAME{i},'HEAT:C') && ...
            ~strcmp(RESULT.UNIT.NAME{i},'HEAT:C2')
        stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'F(IN)'));
        T1 = RESULT.STREAM.TEMPERATURE(strcmp(RESULT.STREAM.NAME(:), stname),1); % [K]
        
        stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'P(OUT)'));
        T2 = RESULT.STREAM.TEMPERATURE(strcmp(RESULT.STREAM.NAME(:), stname),1); % [K]
        heat_duty = abs(RESULT.UNIT.HEATDUTY{i}); %  [J/s]
        
        if T1-T2 > 0
            % cooling
            if T2 <= -101.111 +273.15
                cost_heater = COST.utility.Rn150 * heat_duty *3600 * COST.utility.operating_hour;
                disp('infeasible temperature (CONDENSOR) check the steam');
            elseif -101.111 + 273.15<=T2 && T2 <= -67.7778 + 273.15
                cost_heater = COST.utility.Rn90 * heat_duty *3600 * COST.utility.operating_hour;
            elseif -67.7778 + 273.15<=T2 && T2 <= -34.4444 + 273.15
                cost_heater = COST.utility.Rn30 * heat_duty *3600 * COST.utility.operating_hour;
            elseif -34.4444 + 273.15<=T2 && T2 <= -12.2222 + 273.15
                cost_heater = COST.utility.Rp10 * heat_duty *3600 * COST.utility.operating_hour;
            elseif -12.2222 + 273.15<=T2 && T2 <= 4.4444 + 273.15
                cost_heater = COST.utility.Rchw * heat_duty *3600 * COST.utility.operating_hour;
            elseif 4.444 + 273.15<=T2 && T2 <= 25 + 273.15
                cost_heater = COST.utility.cw * heat_duty *3600 * COST.utility.operating_hour;
            elseif 25 + 273.15<=T2
                cost_heater = COST.utility.steam50psig * heat_duty *3600 * COST.utility.operating_hour;
            end
            % cost
            OperatingCost.REFRIGERATION=[OperatingCost.REFRIGERATION cost_heater];
            
        elseif T1-T2 < 0
            % heating
            if T2 <=147.778 + 273.15
                cost_heater = COST.utility.steam50psig * heat_duty *3600 * COST.utility.operating_hour;
            elseif 147.778 + 273.15<=T2 && T2 <=185.556 + 273.15
                cost_heater = COST.utility.steam150psig * heat_duty *3600 * COST.utility.operating_hour;
            elseif 185.556 + 273.15<=T2 && T2 <=237.778 + 273.15
                cost_heater = COST.utility.steam450psig * heat_duty *3600 * COST.utility.operating_hour;
            elseif 237.778 + 273.15<=T2
                cost_heater = COST.utility.steam450psig * heat_duty *3600 * COST.utility.operating_hour;
                disp('infeasible temperature (REBOILER) check the steam');
            end
            % cost
            OperatingCost.STEAM=[OperatingCost.STEAM cost_heater];
        end   
    end
end

%% Waste Water Treatment
massFlow_WWT = [];
for i = 1:num_stream
    if strcmp(RESULT.STREAM.NAME{i},'PUR:A:CH')
        massFlow = RESULT.STREAM.MASSFLOW{i}; % [kg/s]
        massFlow = sum([massFlow{:,2}]);
        massFlow_WATER = sum([RESULT.STREAM.MASSFLOW{i}{(strcmp({RESULT.STREAM.MASSFLOW{i}{:,1}},'WATER')),2}]);
        massFlow_ORGANIC = massFlow - massFlow_WATER;
        massFlow_WWT =[massFlow_WWT  massFlow_ORGANIC];        
    end
end
massFlow_WWT = sum(massFlow_WWT);
OperatingCost.WWT = massFlow_WWT * COST.utility.wastewt * 3600 * ...
    COST.utility.operating_hour; % kg/s * $/kg -> $/s *3600  $/hr *operating hour -> $/yr

%% CO2 Capture cost
massFlow_CO2 = [];
for i = 1:num_stream
    if strcmp(RESULT.STREAM.NAME{i},'S11-16')
        massFlow_temp = sum([RESULT.STREAM.MASSFLOW{i}{(strcmp({RESULT.STREAM.MASSFLOW{i}{:,1}},'CARBO-02')),2}]);
        massFlow_CO2 = [massFlow_CO2 massFlow_temp];        
    end
end
massFlow_CO2 = sum(massFlow_CO2);
OperatingCost.CO2_Capture = massFlow_CO2 * COST.feed.CO2 * 3600 * ...
    COST.utility.operating_hour; % kg/s * $/kg -> $/s *3600  $/hr *operating hour -> $/yr

RESULT.OperatingCost = OperatingCost;
