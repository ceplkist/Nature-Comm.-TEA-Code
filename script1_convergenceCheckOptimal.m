clc;
clear all;
setpaths;
setcolors;
% global RESULT
RESULT=cell(288,4);
% count=1;
load materials.mat
load superstructure.mat;
worker_num = 9;

% generate each folder and copy the files
for i=1:worker_num
    mydir = fullfile(pwd, ['Functions\ASPEN_FILE\', num2str(i)]);
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

for i=1:worker_num
    mydir = fullfile(pwd, ['Functions\ASPEN_FILE\', num2str(i)]);
    disp(mydir)
    mkdir(mydir);
    %copy file
    copyfile([pwd,'\Functions\ASPEN_FILE\Final\basefile_include_reactor_PR.bkp'],mydir,'f');
    copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA1.atmlz'],mydir,'f');
    copyfile([pwd,'\Functions\ASPEN_FILE\Final\PSA2.atmlz'],mydir,'f');    
end

parpool(worker_num);

for i=1:16
    parfor j= 1:18
        labindex = mod(j,worker_num)+1;
        [NAME, cputime, DATA, errorIndicator]  = singleRun(i,j,materials,superstructure,labindex);
        temp_RESULT(j,:) = {NAME DATA.ConvergenceState cputime DATA errorIndicator};
    end
    for j=1:18
        RESULT{(i-1)*18+j,1} = temp_RESULT{j,1};
        RESULT{(i-1)*18+j,2} = temp_RESULT{j,2};
        RESULT{(i-1)*18+j,3} = temp_RESULT{j,3};
        RESULT{(i-1)*18+j,4} = temp_RESULT{j,4};
        RESULT{(i-1)*18+j,5} = temp_RESULT{j,5};
    end
    save RESULT_optimal.mat RESULT
end

%% NPV = NaN 가끔 되는 녀석들 때문에 추가
% for i=1:16
%     for j= 1:18
%         if isnan(RESULT{(i-1)*18+j,4}.NPV)
%             (i-1)*18+j
%             [NAME, cputime, DATA] = forNaN(i,j,materials,superstructure,RESULT);
%             RESULT{(i-1)*18+j,4} = DATA;
%         end
%     end
% end


%% Cost
for i=1:16
    for j= 1:18
        DATA = RESULT{(i-1)*18+j,4};
        if ~isnan(DATA.NPV)
            CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
            AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
            cost_optimal;
           
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
            A=[]; b=[]; Aeq = [0 1]; beq = [0]; lb = [0 0]; ub = [500 500];
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
            RESULT{(i-1)*18+j,4}.optimization = DATA.optimization;
            
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
save RESULT_optimal_95_2.mat RESULT
%% Figure
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];

for i=1:16
    for j=1:18
        ConvergenceStateMtx(i,j) = RESULT{(i-1)*18+j,2};
        temp = RESULT{(i-1)*18+j,4};
        NPV(i,j) = temp.NPV;
        if i~=1
            Recovery_C_Mtx(i,j) = temp.OUTPUT.CathodeProduct.moleFlow(2)/temp.OUTPUT.CathodeProduct.reactionRate(2);
            Purity_C_Mtx(i,j) = temp.OUTPUT.CathodeProduct.massFrac(2);
        else
            Recovery_C_Mtx(i,j) = temp.OUTPUT.CathodeProduct.moleFlow(1)/temp.OUTPUT.CathodeProduct.reactionRate(1);
            Purity_C_Mtx(i,j) = temp.OUTPUT.CathodeProduct.massFrac(1);
        end
        if j~=1
            Recovery_A_Mtx(i,j) = temp.OUTPUT.AnodeProduct.moleFlow(2)/temp.OUTPUT.AnodeProduct.reactionRate(2);
            Purity_A_Mtx(i,j) = temp.OUTPUT.AnodeProduct.massFrac(2);
        else
            Recovery_A_Mtx(i,j) = temp.OUTPUT.AnodeProduct.moleFlow(1)/temp.OUTPUT.AnodeProduct.reactionRate(1);
            Purity_A_Mtx(i,j) = temp.OUTPUT.AnodeProduct.massFrac(1);
        end
        
        yname{i} = materials.name(CathodeCandidate(i));
        xname{j} = materials.name(AnodeCandidate(j));
    end
end
figure(1)

set(gcf,'position',[10 10 500 600])
imagesc(ConvergenceStateMtx)
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('ConvergenceStateMtx')
set(gcf, 'PaperPositionMode','auto');
figname='ConvergencStateMtx';
print('-dpng',figname,'-r300');

figure(2)
set(gcf,'position',[10 10 500 600])
imagesc(Recovery_C_Mtx)
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('CathodeProductRecovery')
colorbar
set(gcf, 'PaperPositionMode','auto');
figname='CathodeProductRecovery';
print('-dpng',figname,'-r300');

figure(3)
set(gcf,'position',[10 10 500 600])
imagesc(Recovery_A_Mtx)
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('AnodeProductRecovery')
colorbar
set(gcf, 'PaperPositionMode','auto');
figname='AnodeProductRecovery';
print('-dpng',figname,'-r300');

figure(4)
set(gcf,'position',[10 10 500 600])
imagesc(Purity_C_Mtx)
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('CathodeProductPurity')
colorbar
set(gcf, 'PaperPositionMode','auto');
figname='CathodeProductPurity';
print('-dpng',figname,'-r300');

figure(5)
set(gcf,'position',[10 10 500 600])
imagesc(Purity_A_Mtx)
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('AnodeProductPurity')
colorbar
set(gcf, 'PaperPositionMode','auto');
figname='AnodeProductPurity';
print('-dpng',figname,'-r300');

figure(6)
set(gcf,'position',[10 10 500 600])
imagesc(log10(abs(NPV)))
axis square
yticks(linspace(1,16,16))
xticks(linspace(1,18,18))
xticklabels(xname);
xtickangle(90)
yticklabels(yname);
title('NPV')
colorbar
set(gcf, 'PaperPositionMode','auto');
figname='NPV';
print('-dpng',figname,'-r300');

%%
function [NAME, cputime, DATA, errorIndicator] = singleRun(i,j,materials,superstructure,labindex)
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%Select the Products%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%16 cathode products, 18 anode products
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
%% electrolyzer
input.PV = 40; % MW
input.Solar = 6.65*1000; %(https://www.nrel.gov/gis/data-solar.html) annual average for california DNI State
% 'REC:CO2','REC:C:EL','REC:A:EL','REC:A:CH','REC:COP'
input.Ratio = [0.95 0.95 0.95 0.95 0.95]; % not to purge stream 가정
input.temperature = 298.15; % K
input.pressure    = 101325; % Pa

Efficiency.panel = 0.17; %그냥 가정 적절한 값임
Efficiency.ratio = 0.2; %그냥 가정 적절한 값임
CurrentDensity = 2000; %mA/cm2
cost_optimal; % pre-defined COST
type = 4;

if i == 1
    components.cathode = [1];
    Efficiency.FaradayEfficiency.cathode = [1];
    COST.product.cathode = [COST.hydrogen]; %$/kg
    C_potential = materials.potential(1);
    C_overpotential = materials.standard_potential(1) - materials.potential(1);
else
    components.cathode = [1 CathodeCandidate(i)];
    Efficiency.FaradayEfficiency.cathode = [0.01 0.99];
    COST.product.cathode = [COST.hydrogen COST.cathode]; %$/kg
    %     if ~isnan(materials.potential(CathodeCandidate(i)))
    C_potential = materials.potential(CathodeCandidate(i));
    C_overpotential = materials.standard_potential(CathodeCandidate(i)) -...
        materials.potential(CathodeCandidate(i));
    %     else
    %         C_potential = materials.standard_potential(CathodeCandidate(i))-2;
    %     end
end

if j==1
    components.anode = [19];
    Efficiency.FaradayEfficiency.anode = [1];
    COST.product.anode = [COST.oxygen]; %$/kg
    A_potential = materials.potential(19);
    A_overpotential =  materials.potential(19) - materials.standard_potential(19);
else
    components.anode = [19 AnodeCandidate(j)];
    Efficiency.FaradayEfficiency.anode = [0.01 0.99];
    COST.product.anode = [COST.oxygen COST.anode]; %$/kg
    %     if ~isnan(materials.potential(AnodeCandidate(j)))
    A_potential = materials.potential(AnodeCandidate(j));
    A_overpotential = materials.potential(AnodeCandidate(j)) - ...
        materials.standard_potential(AnodeCandidate(j));
    %     else
    %         A_potential = materials.standard_potential(AnodeCandidate(j))+2;
    %     end
end
potential = A_potential - C_potential;
overpotential = A_overpotential + C_overpotential;

if overpotential >=potential
    potential = potential * 0.1; % Galvanic cell이 되어버리면 안되므로
else
    potential = potential-overpotential*(1-0.1); % Overpotential이 없어지는 효과
end

cascade            = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% components.cathode: 1xn (1-18)   ex) [1 3 4] --> hydrogen+CO+formic acid
% components.anode  : 1xm (19-39)  ex) [19 24] --> O2 + FDCA
%  CATHODE PRODUCT
% 1	hydrogen
% *2	syngas
% 3	carbon monoxide
% 4	formate
% 5	methanol
% 6	methane
% 7	ethylene
% 8	ethanol
% 9	n-propanol
% 10	acetaldehyde
% *11	glyoxal
% 12	hydroxyacetone (acetol)
% 13	acetone
% 14	acetate
% 15	Allyl alcohol
% 16	glycolaldehyde
% 17	propionaldehyde
% 18	ethylene glycol
%  ANODE PRODUCT
% 19	Oxygen
% 20	Hydrogen Peroxide
% 21	Acetaldehyde
% 22	Acetic acid
% 23	Ethyl acetate
% 24	Acrylic acid
% 25	Lactic acid (from 1,2-propandiol)
% 26	Lactic acid (from glycerol)
% 27	Benzaldehyde
% 28	Benzoic acid
% 29	2-Furoic acid (from Furfuryl alcohol)
% 30	2-Furoic acid (from Furfural)
% 31	2,5-Furandicarboxylic acid (FDCA)
% *32	4-Methoxybenzaldehyde
% *33	Acetophenone
% 34	Acetone
% *35	Phenoxyacetic acid
% 36	Formaldehyde
% 37	Formic acid
% 38	Glycolic acid
% 39	Oxalic acid
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

% 완벽히 수렴이 안되었거나, 비효율적인 공정이면 Error_files에 저장한다.

[DATA.ProductionRate,DATA.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
[DATA] = equipment_capitalcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = operatingcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = cash_flow(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);

if DATA.ConvergenceState ~=8 || sum(errorIndicator) > 0 || isnan(DATA.NPV)
    disp(['Error: ', num2str(DATA.ConvergenceState),' ',char(NAME)]);
    h.SaveAs(strjoin([pwd,'\Functions\ASPEN_FILE\Error_Files\',strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),''),' ',num2str([DATA.ConvergenceState errorIndicator]),'.bkp'],''));
end

%% The levelized cost calculation
% Case 1: price of anode product (2) eq 0
% if ~isnan(DATA.NPV)
%     fun = @(x) cash_flow_levelizedcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h, x);
%     A=[]; b=[]; Aeq = [0 1]; beq = [0]; lb = [0 0]; ub = [100 100];
%     x0 = [50 50];
%     options = optimoptions('fmincon','Display','off','Algorithm','sqp');
%     [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
%     DATA.optimization(1,1:2) =X;
%     DATA.optimization(1,3) =Fval;
%     % Case 2: price of cathode product (2) eq 0
%     Aeq = [1 0]; beq = [0];
%     options = optimoptions('fmincon','Display','iter','Algorithm','sqp');
%     [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
%     DATA.optimization(2,1:2) =X;
%     DATA.optimization(2,3) =Fval;
% end

% plot([DATA.optimization(:,1)]', [DATA.optimization(:,2)]','--gs','linewidth',1.2,...
%     'MarkerSize',10,...
%     'MarkerEdgeColor','b',...
%     'MarkerFaceColor',[0.5,0.5,0.5])
% ylabel('C_{anode}');
% xlabel('C_{cathode}');
% set(gca,'linewidth',1,'layer','top')
% axis square
% grid on
% grid minor

cputime = toc;
disp(['Iter: ',num2str(18*(i-1)+j),'  |  Labindex: ',num2str(workerID), ...
    '  |  cputime: ',num2str(cputime),'  |  Conv: ',num2str(DATA.ConvergenceState), ...
    '  |  NPV: ',num2str(DATA.NPV), ...
    '  |  Error: ',num2str(errorIndicator), '  |',char(NAME)]);

release(h);
pause(2);
end

%%
function [NAME, cputime, DATA] = forNaN(i,j,materials,superstructure,RESULT)
tic;
%%%%%%%%%%%%%%%%%%%%%%%%%Select the Products%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%16 cathode products, 18 anode products
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
%% electrolyzer
input.PV = 40; % MW
input.Solar = 6.65*1000; %(https://www.nrel.gov/gis/data-solar.html) annual average for california DNI State
% 'REC:CO2','REC:C:EL','REC:A:EL','REC:A:CH','REC:COP'
input.Ratio = [0.95 0.95 0.95 0.95 0.95]; % not to purge stream 가정
input.temperature = 298.15; % K
input.pressure    = 101325; % Pa

Efficiency.panel = 0.17; %그냥 가정
Efficiency.ratio = 0.2; %그냥 가정
CurrentDensity = 500; %mA/cm2
cost_optimal; % pre-defined COST
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
% 1	hydrogen
% *2	syngas
% 3	carbon monoxide
% 4	formate
% 5	methanol
% 6	methane
% 7	ethylene
% 8	ethanol
% 9	n-propanol
% 10	acetaldehyde
% *11	glyoxal
% 12	hydroxyacetone (acetol)
% 13	acetone
% 14	acetate
% 15	Allyl alcohol
% 16	glycolaldehyde
% 17	propionaldehyde
% 18	ethylene glycol
%  ANODE PRODUCT
% 19	Oxygen
% 20	Hydrogen Peroxide
% 21	Acetaldehyde
% 22	Acetic acid
% 23	Ethyl acetate
% 24	Acrylic acid
% 25	Lactic acid (from 1,2-propandiol)
% 26	Lactic acid (from glycerol)
% 27	Benzaldehyde
% 28	Benzoic acid
% 29	2-Furoic acid (from Furfuryl alcohol)
% 30	2-Furoic acid (from Furfural)
% 31	2,5-Furandicarboxylic acid (FDCA)
% *32	4-Methoxybenzaldehyde
% *33	Acetophenone
% 34	Acetone
% *35	Phenoxyacetic acid
% 36	Formaldehyde
% 37	Formic acid
% 38	Glycolic acid
% 39	Oxalic acid
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
pfad = strjoin(['C:\Users\UngLab\Google 드라이브\e-chemical\Functions\ASPEN_FILE\Error_Files\',NAME,' ',num2str([RESULT{(i-1)*18+j,2} RESULT{(i-1)*18+j,5}]),'.bkp'],'')
% 아스펜 골격 제작
h = actxserver('Apwn.Document');                                           %active X handle
invoke(h,'InitFromArchive2', pfad);
% 무언가의 이유로 Visible 했다 꺼야 정상적으로 작동
% set(h, 'Visible', 1);
[G,process] = gen_process_GSA(materials,superstructure, components, cascade,workerID,NAME);
[DATA, h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h);
[DATA.ProductionRate,DATA.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
[DATA] = equipment_capitalcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = operatingcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = cash_flow(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
% set(h, 'Visible', 0);


cputime = toc;


release(h);
pause(2);
end
