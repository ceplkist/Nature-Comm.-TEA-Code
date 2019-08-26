clc;
clear all;
setpaths;
setcolors;
load materials.mat
load superstructure.mat;
worker_num = 10;
% global file_name h1 h2 h3 h4 h5 h6 h7 h8 h9
parpool(worker_num);
i=[2];
j=[12];

%% generate each folder and copy the files
for tt=1:worker_num
    mydir = fullfile(pwd, ['Functions\ASPEN_FILE\', num2str(tt)]);
    if exist(mydir)
        rmdir(mydir,'s');
    end
end
mydir = fullfile(pwd, ['Functions\ASPEN_FILE\Error_Files']);
if exist(mydir)
    rmdir(mydir,'s');
end
pause(3);
mkdir(mydir);

for tt=1:worker_num
    mydir = fullfile(pwd, ['Functions\ASPEN_FILE\', num2str(tt)]);
    disp(mydir)
    mkdir(mydir);
    if tt==1 %gen file
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\basefile_include_reactor_PR.bkp'],mydir,'f');
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA1.atmlz'],mydir,'f');
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA2.atmlz'],mydir,'f');
        [NAME, DATA]  = singleRun(i,j,materials,superstructure,tt);
    else %copy file
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\basefile_include_reactor_PR.bkp'],mydir,'f');
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA1.atmlz'],mydir,'f');
        copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA2.atmlz'],mydir,'f');
        copyfile(DATA.Dir,mydir,'f');
    end
end

%% Sampling
Contour_handle =  @(x)objective_contour_CD_FE(x,i,j,materials,superstructure);
count = 1;
num_sampling = 20;
i_value = linspace(0.99, 0.01, num_sampling);
j_value = linspace(0.2, 0.01, num_sampling);

% check the previous file
if exist('RESULT_contour.mat') == 2
    load RESULT_contour.mat
    RESULT_length = length(RESULT);
else
    RESULT_length = 0;
end

for tt=RESULT_length/num_sampling+1:num_sampling
    parfor jj=1:num_sampling
        [NAME, cputime, DATA, errorIndicator] = Contour_handle([i_value(tt) j_value(jj) j_value(jj)  0.5])
        temp_RESULT(jj,:) = {NAME DATA.ConvergenceState cputime DATA errorIndicator};
    end
    for jj=1:num_sampling
        RESULT{(tt-1)*num_sampling+jj,1} = temp_RESULT{jj,1};
        RESULT{(tt-1)*num_sampling+jj,2} = temp_RESULT{jj,2};
        RESULT{(tt-1)*num_sampling+jj,3} = temp_RESULT{jj,3};
        RESULT{(tt-1)*num_sampling+jj,4} = temp_RESULT{jj,4};
        RESULT{(tt-1)*num_sampling+jj,5} = temp_RESULT{jj,5};
    end
    save RESULT_contour.mat RESULT
end


%% Cost
for tt=1:num_sampling
    for jj= 1:num_sampling
        DATA = RESULT{(tt-1)*num_sampling+jj,4};
        if ~isnan(DATA.NPV)
            CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
            AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
            cost;
            
            if i == 1
                components.cathode = [1];
                Efficiency.FaradayEfficiency.cathode = [1];
                COST.product.cathode = [COST.hydrogen]; %$/kg
            else
                components.cathode = [1 CathodeCandidate(i)];
                Efficiency.FaradayEfficiency.cathode = [0.1 0.9];
                COST.product.cathode = [COST.hydrogen COST.cathode]; %$/kg
            end
            
            if j==1
                components.anode = [19];
                Efficiency.FaradayEfficiency.anode = [1];
                COST.product.anode = [COST.oxygen]; %$/kg
            else
                components.anode = [19 AnodeCandidate(j)];
                Efficiency.FaradayEfficiency.anode = [0.1 0.9];
                COST.product.anode = [COST.oxygen COST.anode]; %$/kg
            end
            
            
            fun = @(x) cash_flow_levelizedcost(DATA, COST, components, x);
            A=[]; b=[]; Aeq = [0 1]; beq = [0]; lb = [0 0]; ub = [500000 500000];
            x0 = [50 50];
            options = optimoptions('fmincon','Display','off','Algorithm','interior-point');
            [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
            DATA.optimization(1,1:2) =X;
            DATA.optimization(1,3) =Fval;
            % Case 2: price of cathode product (2) eq 0
            Aeq = [1 0]; beq = [0];
            [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
            DATA.optimization(2,1:2) =X;
            DATA.optimization(2,3) =Fval;
            RESULT{(tt-1)*num_sampling+jj,4}.optimization = DATA.optimization;
            
            plot([DATA.optimization(:,1)]', [DATA.optimization(:,2)]','--gs','linewidth',1.2,...
                'MarkerSize',10,...
                'MarkerEdgeColor','b',...
                'MarkerFaceColor',[0.5,0.5,0.5])
            ylabel('C_{anode}');
            xlabel('C_{cathode}');
            set(gca,'linewidth',1,'layer','top')
            axis square
            grid on
            grid minor
            hold on
            drawnow
        end
    end
end
save RESULT_contour.mat RESULT
%%
count = 1;
for tt=1:num_sampling
    for jj=1:num_sampling
        DATA=RESULT{(tt-1)*num_sampling+jj,4};
        try
            cathode_cost((tt-1)*num_sampling+jj) = DATA.optimization(1,1);
            anode_cost((tt-1)*num_sampling+jj) = DATA.optimization(2,2);
        catch
            %             (i-1)*18+j
            cathode_cost((tt-1)*num_sampling+jj) = 50;
            anode_cost((tt-1)*num_sampling+jj) = 50;
        end
        
        
        MarketCost_CATHODE(count) =  materials.price(CathodeCandidate(i));
        MarketCost_ANODE(count) = materials.price(AnodeCandidate(j));
        NPV_TOTAL(count) = DATA.NPV;
        
        C = MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2)/...
            (DATA.optimization(1,1)+MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2));
        LevelizedCostRatio_CATHODE(count) =  DATA.optimization(1,1)*C;
        LevelizedCostRatio_ANODE(count) =  DATA.optimization(2,2)*(1-C);
        LevelizedCost_CATHODE(count) =  DATA.optimization(1,1);
        LevelizedCost_ANODE(count) =  DATA.optimization(2,2);
        rank_index(count) =  LevelizedCostRatio_CATHODE(count)*LevelizedCostRatio_ANODE(count) -...
            MarketCost_CATHODE(count)*MarketCost_ANODE(count);
        Contour_data_cathode(tt,jj) = LevelizedCostRatio_CATHODE(count) ;
        Contour_data_anode(tt,jj) =LevelizedCostRatio_ANODE(count);
        Contour_NPV(tt,jj) = NPV_TOTAL(count) ;
        X((tt-1)*num_sampling+jj) =i_value(tt)*99+1;
        Y((tt-1)*num_sampling+jj) = j_value(jj);
        Z((tt-1)*num_sampling+jj) = LevelizedCostRatio_CATHODE(count);
        Z_NPV((tt-1)*num_sampling+jj) = NPV_TOTAL(count);
        %             plot([DATA.optimization(:,1)]', [DATA.optimization(:,2)]','--gs','linewidth',1.2,...
        %                 'MarkerSize',10,...
        %                 'MarkerEdgeColor','b',...
        %                 'MarkerFaceColor',[0.5,0.5,0.5])
        %             ylabel('C_{anode}');
        %             xlabel('C_{cathode}');
        %             set(gca,'linewidth',1,'layer','top')
        %             axis square
        %             grid on
        %             grid minor
        %             hold on
        %             drawnow
        count = count+1;       
    end
end


%%
function [NAME, DATA] = singleRun(i,j,materials,superstructure,labindex)
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%Select the Products%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%16 cathode products, 18 anode products
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
%% electrolyzer
input.PV = 40; % MW
input.Solar = 6.65*1000; %(https://www.nrel.gov/gis/data-solar.html) annual average for california DNI State
% 'REC:CO2','REC:C:EL','REC:A:EL','REC:A:CH','REC:COP'
input.Ratio = [0.90 0.90 0.90 0.90 0.90]; % not to purge stream 가정
input.temperature = 298.15; % K
input.pressure    = 101325; % Pa

Efficiency.panel = 0.17; %그냥 가정 적절한 값임
Efficiency.ratio = 0.2; %그냥 가정 적절한 값임
CurrentDensity = 100; %mA/cm2
cost; % pre-defined COST
type = 3;

if i == 1
    components.cathode = [1];
    Efficiency.FaradayEfficiency.cathode = [1];
    COST.product.cathode = [COST.hydrogen]; %$/kg
    C_potential = materials.potential(1);
else
    components.cathode = [1 CathodeCandidate(i)];
    Efficiency.FaradayEfficiency.cathode = [0.1 0.9];
    COST.product.cathode = [COST.hydrogen COST.cathode]; %$/kg
    if ~isnan(materials.potential(CathodeCandidate(i)))
        C_potential = materials.potential(CathodeCandidate(i));
    else
        C_potential = materials.standard_potential(CathodeCandidate(i))-2;
    end
end

if j==1
    components.anode = [19];
    Efficiency.FaradayEfficiency.anode = [1];
    COST.product.anode = [COST.oxygen]; %$/kg
    A_potential = materials.potential(19);
else
    components.anode = [19 AnodeCandidate(j)];
    Efficiency.FaradayEfficiency.anode = [0.1 0.9];
    COST.product.anode = [COST.oxygen COST.anode]; %$/kg
    if ~isnan(materials.potential(AnodeCandidate(j)))
        A_potential = materials.potential(AnodeCandidate(j));
    else
        A_potential = materials.standard_potential(AnodeCandidate(j))+2;
    end
end



potential = A_potential - C_potential;
cascade            = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% components.cathode: 1xn (1-18)   ex) [1 3 4] --> hydrogen+CO+formic acid
% components.anode  : 1xm (19-39)  ex) [19 24] --> O2 + FDCA
%  CATHODE PRODUCT
% 1	hydrogen 1
% *2	syngas
% 3	carbon monoxide 2
% 4	formate 3
% 5	methanol 4
% 6	methane 5
% 7	ethylene 6
% 8	ethanol 7
% 9	n-propanol 8
% 10	acetaldehyde 9
% *11	glyoxal
% 12	hydroxyacetone (acetol) 10
% 13	acetone 11
% 14	acetate 12
% 15	Allyl alcohol 13
% 16	glycolaldehyde 14
% 17	propionaldehyde 15
% 18	ethylene glycol 16
%  ANODE PRODUCT
% 19	Oxygen 1
% 20	Hydrogen Peroxide 2
% 21	Acetaldehyde 3
% 22	Acetic acid 4
% 23	Ethyl acetate 5
% 24	Acrylic acid 6
% 25	Lactic acid (from 1,2-propandiol) 7
% 26	Lactic acid (from glycerol) 8
% 27	Benzaldehyde 9
% 28	Benzoic acid 10
% 29	2-Furoic acid (from Furfuryl alcohol) 11
% 30	2-Furoic acid (from Furfural) 12
% 31	2,5-Furandicarboxylic acid (FDCA) 13
% *32	4-Methoxybenzaldehyde
% *33	Acetophenone
% 34	Acetone 14
% *35	Phenoxyacetic acid
% 36	Formaldehyde 15
% 37	Formic acid 16
% 38	Glycolic acid 17
% 39	Oxalic acid 18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generate Superstructure and fixed structure
%pre-defined super-structure
workerID =  labindex;
NAME = strjoin([strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),'')],'');



%% Calculate Process Model

% 기본세팅
[ProductionRate,Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
input.CO2 = max(sum(ProductionRate.cathode(:).*materials.carbon(components.cathode(:))),0.01)*1.1+0.00001;
input.CH  = sum(ProductionRate.anode(:).*materials.carbon(components.anode(:)))*1.1;
water_temp = cell2mat(materials.water);
input.WATER = sum(ProductionRate.anode(:).*water_temp(components.anode(:)))*1.1;

% 아스펜 골격 제작
[G,process,h] = gen_process(materials,superstructure, components, cascade,workerID,NAME);
% 무언가의 이유로 Visible 했다 꺼야 정상적으로 작동
set(h, 'Visible', 1);
set(h, 'Visible', 0);

% Run하고 데이터 뽑기, 뭔가의 문제로 오류가 나면 reinitialize하고 다시 돌리고 결과 뽑기. 그래도 에러가 나면 뭔가
% 문제가 있는 것이므로 오류 반환 후 종료
try
    [ConvergenceState, h] = cal_process(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
    [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
catch
    h.Reinit;
    h.Engine.Run2;
    [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
end

% If no water or CO2 then
inletError = false;
if length(components.anode)==2
    temp =strjoin(["\Data\Streams\INL:CH\Input\FLOW\MIXED\",materials.raw_materials(components.anode(2))],'');
    if isnan(h.Tree.FindNode(temp).value)
        h.Tree.FindNode(temp).value...                                         Flowrate [kmol/s]
            = input.CH/1000;
        inletError = true;
    end                                                                    %marginal supply
end
if isnan(h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value)
    h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value...    Flowrate [kmol/s]
        = input.WATER/1000; % electrolyte
    inletError = true;
end

if isnan(h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value)
    h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value...    Flowrate [kmol/s]
        = input.CO2/1000; % electrolyte
    inletError = true;
end

if inletError
    % Initialize the Aspen simulation
    h.Reinit;
    % Run the Aspen simulation
    h.Engine.Run2;
    [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
end
%Indicate the error or inefficient process
errorIndicator = [false false];
if length(components.cathode) == 2
    if strcmp(char(materials.phase(components.cathode(2))),'l')
        if DATA.OUTPUT.CathodeProduct.moleFlow(2)/DATA.OUTPUT.CathodeProduct.reactionRate(2) <=0.6
            errorIndicator(1) = true;
        end
    end
end
if length(components.anode) == 2
    if DATA.OUTPUT.AnodeProduct.moleFlow(2)/DATA.OUTPUT.AnodeProduct.reactionRate(2) <=0.6
        errorIndicator(2) = true;
    end
end

% 만약 error가 나거나 효율적이지 못한 이유로 recovery가 0.6 이하일 경우 alternative 공정 (flash 한개
% 더)로 바꾸고 다시 수렴시킨다. 종종 여기서도 에러가 (block이 안펴져서 값이 안들어가는 이상한 에러) 나므로 이를 해결하기
% 위해 아에 처음부터 만드는 코드를 사용한다.
if sum(errorIndicator)>0
    try
        [ConvergenceState,h] = gencal_process_forError(Efficiency, CurrentDensity, potential, materials, components, input, process, h, errorIndicator);
        [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
    catch
        release(h);
        pause(2);
        [G,process,h] = gen_process(materials,superstructure, components, cascade,workerID,NAME);
        set(h, 'Visible', 1);
        set(h, 'Visible', 0);
        [h] = cal_process_norun(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
        [ConvergenceState,h] = gencal_process_forError(Efficiency, CurrentDensity, potential, materials, components, input, process, h, errorIndicator);
        [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
    end
end


% If no chemical, CO2, or water then
inletError = false;
if length(components.anode)==2
    temp =strjoin(["\Data\Streams\INL:CH\Input\FLOW\MIXED\",materials.raw_materials(components.anode(2))],'');
    if isnan(h.Tree.FindNode(temp).value)
        h.Tree.FindNode(temp).value...                                         Flowrate [kmol/s]
            = input.CH/1000;
        inletError = true;
    end                                                                    %marginal supply
end

if isnan(h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value)
    h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value...    Flowrate [kmol/s]
        = input.WATER/1000; % electrolyte
    inletError = true;
end
if isnan(h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value)
    h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value...    Flowrate [kmol/s]
        = input.WATER/1000; % electrolyte
    inletError = true;
end

if inletError
    % Initialize the Aspen simulation
    h.Reinit;
    % Run the Aspen simulation
    h.Engine.Run2;
    [DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
end


% Save the error or inefficient file
%Indicate the error or inefficient process
errorIndicator = [false false];
if length(components.cathode) == 2
    if strcmp(char(materials.phase(components.cathode(2))),'l')
        if DATA.OUTPUT.CathodeProduct.moleFlow(2)/DATA.OUTPUT.CathodeProduct.reactionRate(2) <=0.6
            errorIndicator(1) = true;
        end
    end
end
if length(components.anode) == 2
    if DATA.OUTPUT.AnodeProduct.moleFlow(2)/DATA.OUTPUT.AnodeProduct.reactionRate(2) <=0.6
        errorIndicator(2) = true;
    end
end

% 그냥 저장
DATA.Dir = strjoin([pwd,'\Functions\ASPEN_FILE\',num2str(labindex),'\',strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),''),'.bkp'],'');
h.SaveAs(DATA.Dir);

[DATA.ProductionRate,DATA.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
[DATA] = equipment_capitalcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = operatingcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = cash_flow(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);

cputime = toc;
disp(['Iter: ',num2str(18*(i-1)+j),'  |  Labindex: ',num2str(workerID), ...
    '  |  cputime: ',num2str(cputime),'  |  Conv: ',num2str(DATA.ConvergenceState), ...
    '  |  NPV: ',num2str(DATA.NPV), ...
    '  |  Error: ',num2str(errorIndicator), '  |',char(NAME)]);
release(h);
pause(2);
end