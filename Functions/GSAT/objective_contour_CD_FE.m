function [NAME, cputime, DATA, errorIndicator]  = objective_contour_CD_FE(x,i,j,materials,superstructure)
tic;
%%%%%%%%%%%%%%%%%%%%%%%%%Select the Products%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%16 cathode products, 18 anode products
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
%% electrolyzer
% x=[input.PV input.Ratio CurrentDensity, Faraday efficiency Product_Cost]
%min=[20 0 0 0 0 100 0 0 2 2];
%max=[80 1 1 1 1 600 1 1 4 4];
input.PV = 40;
input.Ratio(1:3) = [0.9 0.9 0.9];
input.Ratio(4)   = 0.9; %cascade
input.Ratio(5)   = 0.9;

input.temperature = 298.15; % K
input.pressure    = 101325; % Pa
input.Solar = 6.65*1000; %(https://www.nrel.gov/gis/data-solar.html) annual average for california DNI State
Efficiency.panel = 0.17; %그냥 가정 적절한 값임
Efficiency.ratio = 0.2; %그냥 가정 적절한 값임
CurrentDensity = 99*x(1)+1; %mA/cm2
cost; % pre-defined COST
type = 3;

if i == 1
    components.cathode = [1];
    Efficiency.FaradayEfficiency.cathode = [1];
    COST.product.cathode = [COST.hydrogen]; %$/kg
    C_potential = materials.potential(1);
    C_overpotential = materials.standard_potential(1) - materials.potential(1);
else
    components.cathode = [1 CathodeCandidate(i)];
    Efficiency.FaradayEfficiency.cathode = [1-x(2) x(2)];
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
    Efficiency.FaradayEfficiency.anode = [1-x(3) x(3)];
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
    potential = potential * x(4); % Galvanic cell이 되어버리면 안되므로
else
    potential = potential-overpotential*(1-x(4)); % Overpotential이 없어지는 효과
end

cascade            = 0;
DATA.GSAinput = [CurrentDensity x(2) x(3) potential];


%% Generate Superstructure and fixed structure
haha = getCurrentTask();
labindex=haha.ID;
workerID  = labindex;
NAME = strjoin([strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),'')],'');


%% Calculate Process Model
% 기본세팅
[ProductionRate,Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
input.CO2 = max(sum(ProductionRate.cathode(:).*materials.carbon(components.cathode(:))),0.01)*1.1+0.00001;
input.CH  = sum(ProductionRate.anode(:).*materials.carbon(components.anode(:)))*1.1;
water_temp = cell2mat(materials.water);
input.WATER = sum(ProductionRate.anode(:).*water_temp(components.anode(:)))*1.1;
DATA.Dir = strjoin([pwd,'\Functions\ASPEN_FILE\',num2str(labindex),'\',strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),''),'.bkp'],'');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 아스펜 연결
% try
%     h = actxserver('Apwn.Document');                                           %active X handle
%     invoke(h,'InitFromArchive2', DATA.Dir);
% catch
%     pause(5)
%     h = actxserver('Apwn.Document');                                           %active X handle
%     invoke(h,'InitFromArchive2', DATA.Dir);
% end
% % 아스펜 골격 제작
% [G,process] = gen_process_GSA(materials,superstructure, components, cascade,workerID,NAME);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 아스펜 골격 제작
% [G,process] = gen_process_GSA(materials,superstructure, components, cascade,workerID,NAME);
% 무언가의 이유로 Visible 했다 꺼야 정상적으로 작동


[G,process,h] = gen_process(materials,superstructure, components, cascade,workerID,NAME);
% 무언가의 이유로 Visible 했다 꺼야 정상적으로 작동
set(h, 'Visible', 1);
set(h, 'Visible', 0);

% Run하고 데이터 뽑기, 뭔가의 문제로 오류가 나면 reinitialize하고 다시 돌리고 결과 뽑기. 그래도 에러가 나면 뭔가
% 문제가 있는 것이므로 오류 반환 후 종료
% switch ENDindex
%     case 1
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


%% 경제성 평가
[DATA.ProductionRate,DATA.Area] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input);
[DATA] = equipment_capitalcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = operatingcost(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);
[DATA] = cash_flow(DATA,input, COST, Efficiency, CurrentDensity, potential, components, h);

if isnan(DATA.NPV)
    disp(['Error: ', num2str(DATA.ConvergenceState),' ',char(NAME)]);    
    disp(['NPV error fuck!']);
    h.SaveAs(strjoin([pwd,'\Functions\Error_Files\',strjoin(materials.name(components.cathode),''),'-',strjoin(materials.name(components.anode),''),' ',num2str(labindex),' ',num2str(ceil(CurrentDensity)),'.bkp'],''));
end

cputime = toc;
disp([' Labindex: ',num2str(workerID), ...
    '  |  cputime: ',num2str(cputime),'  |  Conv: ',num2str(DATA.ConvergenceState), ...
    '  |  NPV: ',num2str(DATA.NPV), ...
    '  |  Error: ',num2str(errorIndicator), '  |',char(NAME)]);

release(h);
pause(1);

end

