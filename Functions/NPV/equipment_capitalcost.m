function [RESULT] = equipment_capitalcost(RESULT,input, COST, Efficiency, CurrentDensity, potential, components, h)
option.COSTSHEET=false;
option.FIGURE = false;
%% Results Update for Techno-economic analysis
% Recalculation for electrolyzer output
num_unit = size(RESULT.UNIT,1);
load materials.mat
[RESULT.ProductionRate,RESULT.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
[CapitalCosts.electrolyzer, ReferredDATA] = NPV_electrolyzer(RESULT,input, COST, CurrentDensity, potential);



% Flash ($)
CapitalCosts.flash=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Flash2')
        stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'L(OUT)')); % Flash liquid 부분으로 나가는 stream 정보 따기
        LFlow = RESULT.STREAM.MASSFLOW{strcmp(RESULT.STREAM.NAME(:), stname),1}; % [kg/s]
        LFlow = sum([LFlow{:,2}]);
        LDensity = RESULT.STREAM.DENSITY(strcmp(RESULT.STREAM.NAME(:), stname),1); %[kg/cum]
        VesselPressure = RESULT.UNIT.PRESSURE{i}; %  [Pa]
        [cost]                      = NPV_flash(LFlow,LDensity,VesselPressure,COST.UPF);
        CapitalCosts.flash = [CapitalCosts.flash cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end

% Distillation Column ($)
CapitalCosts.distillation=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Distl') || strcmp(RESULT.UNIT.UNIT_NAME{i},'RadFrac')
        P_col = input.pressure/10^5; % [Pa to bar]
        S_col = 10; % number of tray
        
        % Reboiler
        if strcmp(RESULT.UNIT.UNIT_NAME{i},'Distl')
            feedtemp = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\FEED_TRAY_T']).value; %[K]
            stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'D(OUT)'));
            COND_index = 'COND_TYPE';
        elseif strcmp(RESULT.UNIT.UNIT_NAME{i},'RadFrac')
            feedtemp = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\B_TEMP\5']).value; %[K]
            stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'VD(OUT)'));
            COND_index = 'CONDENSER';
        end
        bottomtemp = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\BOTTOM_TEMP']).value; %[K]
        heat_duty = RESULT.UNIT.REBDUTY{i}; %  [J/s]
        [cost_reboiler] = NPV_heater(feedtemp,bottomtemp,P_col,heat_duty,COST.UPF);
        % Condensor
        toptemp  = h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Output\TOP_TEMP']).value; %[K]
        heat_duty = RESULT.UNIT.CONDDUTY{i}; %  [J/s]
        [cost_condensor] = NPV_heater(feedtemp,toptemp,P_col,heat_duty,COST.UPF);
 
        outlet_distillate = RESULT.STREAM.MASSFLOW{strcmp(RESULT.STREAM.NAME(:), stname),1}; % [kg/s]
        outlet_distillate = sum([outlet_distillate{:,2}]);
        
        stnameinlet=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'F(IN)'));
        inlet = RESULT.STREAM.MASSFLOW{strcmp(RESULT.STREAM.NAME(:), stnameinlet),1};
        % distl type 1 이면 partial로 수렴시키고 여기서 total을 보고
        % distl type 2 이면 total로 수렴시키고 여기서 partial을 보자
        Sigma = 72; % [dyne/cm] 18.3 for MTBE, 72 for water
        
        if strcmp(h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Input\',COND_index]).value, 'PARTIAL') ||...
                strcmp(h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Input\',COND_index]).value, 'PARTIAL-V')
            try
                Rho_v = h.Tree.FindNode(['\Data\Streams\',char(stname),'\Output\STR_MAIN\RHOMX_MASS\MIXED']).Value; %[kg/cum]
                h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Input\',COND_index]).value = 'TOTAL';
                h.Reinit;
                h.Engine.Run2;
                Rho_l=h.Tree.FindNode(['\Data\Streams\',char(stname),'\Output\STR_MAIN\RHOMX_MASS\MIXED']).Value; %[kg/cum]
            catch
                Rho_v=10;
                Rho_l=1000;
            end
        elseif strcmp(h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Input\COND_TYPE']).value, 'TOTAL')
            try
                Rho_l=h.Tree.FindNode(['\Data\Streams\',char(stname),'\Output\STR_MAIN\RHOMX_MASS\MIXED']).Value; %[kg/cum]
                h.Tree.FindNode(['\Data\Blocks\',char(RESULT.UNIT.NAME{i}),'\Input\COND_TYPE']).value = 'PARTIAL';
                h.Reinit;
                h.Engine.Run2;
                Rho_v=h.Tree.FindNode(['\Data\Streams\',char(stname),'\Output\STR_MAIN\RHOMX_MASS\MIXED']).Value; %[kg/cum]
            catch
                Rho_v=10;
                Rho_l=1000;
            end
        else
            Rho_v=10;
            Rho_l=1000;
        end
        
        
        m_l=outlet_distillate*2; %[kg/s] reflux ratio = 2 and same molecular weight;
        m_v=outlet_distillate*3; %[kg/s]
        [D_Col,H_Col,V_Col,cost_column]                   = NPV_distillation(P_col,S_col, Sigma,Rho_l,Rho_v,m_v,m_l);
        
        % cost
        cost = cost_column + cost_reboiler + cost_condensor;
        CapitalCosts.distillation = [CapitalCosts.distillation cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end

% Extraction column ($)
CapitalCosts.extraction=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.NAME{i},'SEP:C:EX')
        feedname = 'S10-12';
        feed = RESULT.STREAM.VOLFLOW(strcmp(RESULT.STREAM.NAME(:), feedname),1); % [kg/s]
        solventname = 'SEX:C';
        solvent = RESULT.STREAM.VOLFLOW(strcmp(RESULT.STREAM.NAME(:), solventname),1); % [kg/s]
        
        [cost]= NPV_extractor(feed, solvent);
        CapitalCosts.extraction = [CapitalCosts.extraction cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
    if  strcmp(RESULT.UNIT.NAME{i},'SEP:A:EX')
        feedname = 'S13-15';
        feed = RESULT.STREAM.VOLFLOW(strcmp(RESULT.STREAM.NAME(:), feedname),1); % [kg/s]
        solventname = 'SEX:A';
        solvent = RESULT.STREAM.VOLFLOW(strcmp(RESULT.STREAM.NAME(:), solventname),1); % [kg/s]
        
        [cost]= NPV_extractor(feed, solvent);
        CapitalCosts.extraction = [CapitalCosts.extraction cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end

% Pressure Swing Adsorption
CapitalCosts.PSA=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.NAME{i},'PSA1:C')
        V_activecarbon = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Output\FINAL_VAL\1").value;
        P_Col = 27.3; %bar
        [D_Col,H_Col,V_Col,cost]=NPV_PSA(P_Col,V_activecarbon);
        CapitalCosts.PSA = [CapitalCosts.PSA cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
    if strcmp(RESULT.UNIT.NAME{i},'PSA2:C')
        V_activecarbon = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Output\FINAL_VAL\1").value;
        P_Col = 27.3; %bar 비록 1 bar로 운전하겠지만, regeneration 할 때 등 고압이 될일이 있을 것이므로
        [D_Col,H_Col,V_Col,cost]=NPV_PSA(P_Col,V_activecarbon);
        CapitalCosts.PSA = [CapitalCosts.PSA cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end


% Compressor ($)
CapitalCosts.compressor=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Compr')
        Work = RESULT.UNIT.WORK{i}; % [W]
        [cost] = NPV_compressor(Work,COST.UPF);
        CapitalCosts.compressor = [CapitalCosts.compressor cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end

% Heater ($)
% U값이 너무 크게 되어 있는듯? 확인 하고 수정 필요.
CapitalCosts.heater=[];
for i = 1:num_unit
    if strcmp(RESULT.UNIT.UNIT_NAME{i},'Heater') &&...
            ~strcmp(RESULT.UNIT.NAME{i},'HEAT:C') && ...
            ~strcmp(RESULT.UNIT.NAME{i},'HEAT:C2')
        stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'F(IN)'));
        T1 = RESULT.STREAM.TEMPERATURE(strcmp(RESULT.STREAM.NAME(:), stname),1); % [K]
        
        stname=RESULT.UNIT.CONNECTION{i,1}(1,strcmp(RESULT.UNIT.CONNECTION{i,1}(2,:), 'P(OUT)'));
        T2 = RESULT.STREAM.TEMPERATURE(strcmp(RESULT.STREAM.NAME(:), stname),1); % [K]
        P = RESULT.UNIT.PRESSURE{i}; %  [Pa]
        heat_duty = RESULT.UNIT.HEATDUTY{i}; %  [J/s]
        
        [cost] = NPV_heater(T1,T2,P,heat_duty,COST.UPF);
        CapitalCosts.heater = [CapitalCosts.heater cost];
        RESULT.UNIT.CAPITAL_COST(i) = cost;
    end
end




%% Components of Total Capital Investment (TCI)
% Bare-module cost can be calculated by Bare-Module Factors of Guthrie
% (1974) pg 549 of Seider book.
%Total bare-module costs for fabricated equipment  + Total bar-module costs for process machinery + Total bare-module costs for spares + Total bare-module costs for storage and surge tanks
C_EQP        = sum(CapitalCosts.electrolyzer) + ... % electrolyzer
    sum(CapitalCosts.flash) + ...        % flash
    sum(CapitalCosts.compressor) + ...   % compressor
    sum(CapitalCosts.distillation) + ... % distillation
    sum(CapitalCosts.extraction) + ...   % extraction
    sum(CapitalCosts.PSA) + ...           % pressure swing adsorption
    sum(CapitalCosts.heater);            % heater
RESULT.CapitalCosts = CapitalCosts;
