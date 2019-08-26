function [DATA,h] = get_results(Efficiency, CurrentDensity, potential, materials, components, input, process, h)
%% Techno-economic Analysis for Electrochemical Processes
% get_results.m
%
% get the process results from calculated Aspen file
% ------------------------------output-------------------------------------
% output: DATA, h
%
% -------------------------------------------------------------------------
%% Convergence check
DATA.ConvergenceState=h.Tree.FindNode("\Data\Results Summary\Run-Status\Output\UOSSTAT2").value;
%% Input & Output Results (kmol/s)
% DATA.FEED
%           .CO2
%           .WATER
%           .CH
DATA.FEED.CO2.moleFlow = h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value;
DATA.FEED.CO2.massFlow = h.Tree.FindNode("\Data\Streams\INL:CO2\Output\MASSFLOW\MIXED\CARBO-02").value;
DATA.FEED.EL.moleFlow = h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value;
DATA.FEED.EL.massFlow = h.Tree.FindNode("\Data\Streams\INL:EL\Output\MASSFLOW\MIXED\WATER").value;
if process.order.in(3) + process.order.out(3) ~= 0
    temp =strjoin(["\Data\Streams\INL:CH\Input\FLOW\MIXED\",materials.raw_materials(components.anode(2))],'');
    DATA.FEED.CH.moleFlow = h.Tree.FindNode(temp).value;
    temp =strjoin(["\Data\Streams\INL:CH\Output\MASSFLOW\MIXED\",materials.raw_materials(components.anode(2))],'');
    DATA.FEED.CH.massFlow = h.Tree.FindNode(temp).value;
end

% DATA.OUTPUT
%           .CathodeProduct
if length(components.cathode) == 2
    if strcmp(char(materials.phase(components.cathode(2))),'g')
        temp =strjoin(["\Data\Streams\OUT:C:G\Output\MOLEFLOW\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.moleFlow =  [h.Tree.FindNode("\Data\Streams\SPC1-H2\Output\MOLEFLOW\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:G\Output\MOLEFRAC\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.moleFrac =  [h.Tree.FindNode("\Data\Streams\SPC1-H2\Output\MOLEFRAC\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:G\Output\MASSFLOW\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.massFlow =  [h.Tree.FindNode("\Data\Streams\SPC1-H2\Output\MASSFLOW\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:G\Output\MASSFRAC\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.massFrac =  [h.Tree.FindNode("\Data\Streams\SPC1-H2\Output\MASSFRAC\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
    elseif strcmp(char(materials.phase(components.cathode(2))),'l')
        temp =strjoin(["\Data\Streams\OUT:C:L\Output\MOLEFLOW\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.moleFlow =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MOLEFLOW\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:L\Output\MOLEFRAC\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.moleFrac =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MOLEFRAC\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:L\Output\MASSFLOW\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.massFlow =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MASSFLOW\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];
        temp =strjoin(["\Data\Streams\OUT:C:L\Output\MASSFRAC\MIXED\",materials.ASPEN_NAME(components.cathode(2))],'');
        DATA.OUTPUT.CathodeProduct.massFrac =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MASSFRAC\MIXED\HYDRO-01").value   h.Tree.FindNode(temp).value];        
    end
else % Only HER
    DATA.OUTPUT.CathodeProduct.moleFlow =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MOLEFLOW\MIXED\HYDRO-01").value];
    DATA.OUTPUT.CathodeProduct.moleFrac =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MOLEFRAC\MIXED\HYDRO-01").value];
    DATA.OUTPUT.CathodeProduct.massFlow =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MASSFLOW\MIXED\HYDRO-01").value];
    DATA.OUTPUT.CathodeProduct.massFrac =  [h.Tree.FindNode("\Data\Streams\OUT:C:G\Output\MASSFRAC\MIXED\HYDRO-01").value];
end
% Reaction rate cathode
count_comp=1;
temp_comp=[];
for comp = components.cathode
    try
        temp_comp(count_comp) = h.Tree.FindNode(['\Data\Blocks\RXN:C-3\Output\EXTENT_OUT\',num2str(comp)]).value; %[kmol/s]
    catch
        h.Reinit;
        h.Engine.Run2;
        temp_comp(count_comp) = h.Tree.FindNode(['\Data\Blocks\RXN:C-3\Output\EXTENT_OUT\',num2str(comp)]).value; %[kmol/s]
    end
    count_comp=count_comp+1;
end
DATA.OUTPUT.CathodeProduct.reactionRate  = temp_comp;


%           .AnodeProduct
if length(components.anode) == 2
    temp =strjoin(["\Data\Streams\OUT:A:L\Output\MOLEFLOW\MIXED\",materials.ASPEN_NAME(components.anode(2))],'');
    DATA.OUTPUT.AnodeProduct.moleFlow =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MOLEFLOW\MIXED\OXYGE-01").value   h.Tree.FindNode(temp).value];
    temp =strjoin(["\Data\Streams\OUT:A:L\Output\MOLEFRAC\MIXED\",materials.ASPEN_NAME(components.anode(2))],'');
    DATA.OUTPUT.AnodeProduct.moleFrac =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MOLEFRAC\MIXED\OXYGE-01").value   h.Tree.FindNode(temp).value];
    temp =strjoin(["\Data\Streams\OUT:A:L\Output\MASSFLOW\MIXED\",materials.ASPEN_NAME(components.anode(2))],'');
    DATA.OUTPUT.AnodeProduct.massFlow =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MASSFLOW\MIXED\OXYGE-01").value   h.Tree.FindNode(temp).value];
    temp =strjoin(["\Data\Streams\OUT:A:L\Output\MASSFRAC\MIXED\",materials.ASPEN_NAME(components.anode(2))],'');
    DATA.OUTPUT.AnodeProduct.massFrac =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MASSFRAC\MIXED\OXYGE-01").value   h.Tree.FindNode(temp).value];
    
else % Only OER
    DATA.OUTPUT.AnodeProduct.moleFlow =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MOLEFLOW\MIXED\OXYGE-01").value];
    DATA.OUTPUT.AnodeProduct.moleFrac =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MOLEFRAC\MIXED\OXYGE-01").value];
    DATA.OUTPUT.AnodeProduct.massFlow =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MASSFLOW\MIXED\OXYGE-01").value];
    DATA.OUTPUT.AnodeProduct.massFrac =  [h.Tree.FindNode("\Data\Streams\OUT:A:G\Output\MASSFRAC\MIXED\OXYGE-01").value];
end

% Reaction rate anode
count_comp=1;
temp_comp=[];
for comp = components.anode
    temp_comp(count_comp) = h.Tree.FindNode(['\Data\Blocks\RXN:A-2\Output\EXTENT_OUT\',num2str(comp-18)]).value; %[kmol/s]
    count_comp=count_comp+1;
end
DATA.OUTPUT.AnodeProduct.reactionRate  = temp_comp;

% CO2 conversion
% Yield

%% Units Results
allUnits = h.Tree.FindNode("\Data\Blocks");
numUnits = allUnits.Elements.Count;
for i=1:numUnits
    DATA.UNIT{i,1} = allUnits.Elements.ItemName(i-1);
end
for i=1:numUnits
    %     if ~isempty(strfind(DATA.UNIT{i,1},'SEP'))
    try % temperarture
        DATA.UNIT{i,2} = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\B_TEMP']).value; %[K]
    catch
        DATA.UNIT{i,2} = []; %[K]
    end
    try % pressure
        DATA.UNIT{i,3} = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\B_PRES']).value; %[Pa]
    catch
        DATA.UNIT{i,3} = [];
    end
    try % Heat duty
        DATA.UNIT{i,4}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\QCALC']).value; %[W]
    catch
        DATA.UNIT{i,4}  = [];
    end
    try % Condenser duty
        DATA.UNIT{i,5}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\COND_DUTY']).value; %[W]
    catch
        DATA.UNIT{i,5}  = [];
    end
    try % Reboiler duty
        DATA.UNIT{i,6}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\REB_DUTY']).value; %[W]
    catch
        DATA.UNIT{i,6}  = [];
    end
    
    try % Work
        DATA.UNIT{i,7}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\WNET']).value; %[W]
    catch
        DATA.UNIT{i,7}  = [];
    end
    
    try % Balance mole-flow in
        DATA.UNIT{i,8}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\BAL_MOLI_TFL']).value; %[kmol/s]
    catch
        DATA.UNIT{i,8}  = [];
    end
    try % Balance mole-flow out
        DATA.UNIT{i,9}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\BAL_MOLO_TFL']).value; %[kmol/s]
    catch
        DATA.UNIT{i,9}  = [];
    end
    try % Balance mass-flow in
        DATA.UNIT{i,10}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\BAL_MASI_TFL']).value; %[kmol/s]
    catch
        DATA.UNIT{i,10}  = [];
    end
    try % Balance mass-flow out
        DATA.UNIT{i,11}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\BAL_MASO_TFL']).value; %[kmol/s]
    catch
        DATA.UNIT{i,11}  = [];
    end
    try % Balance Enthalpy in
        DATA.UNIT{i,12}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\TOT_ENTH_ABS']).value; %[W]
    catch
        DATA.UNIT{i,12}  = [];
    end
    try % Balance Enthalpy out
        DATA.UNIT{i,13}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Output\BAL_ENTH_OUT']).value; %[W]
    catch
        DATA.UNIT{i,13}  = [];
    end
    
    
    numConnections = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Connections']).Elements.Count;
    temp={};
    for j=1:numConnections % connection
        temp{1,j} =  h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Connections']).Elements.ItemName(j-1);
        temp{2,j} =  h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1},'\Connections\',temp{1,j}]).value;
    end
    DATA.UNIT{i,14} = temp;
    
    try % ASPEN name of unit
        DATA.UNIT{i,15}  = h.Tree.FindNode(['\Data\Blocks\',DATA.UNIT{i,1}]).AttributeValue(6); %[-]
    catch
        DATA.UNIT{i,15}  = [];
    end
    %     end
end

% % SEP:C:GG
% if length(components.cathode) == 1 % only HER -> only CO2 amine scrubbing
%
% end
%
% % For Utilities (Flash heat duty, Distillation column condenser/reboiler,
% % Compressor work, Heat exchanger deat duty, Reactor heat duty
%
% % Design specs (
%

%% Stream Results
allStreams = h.Tree.FindNode("\Data\Streams");
numStreams = allStreams.Elements.Count;
for i=1:numStreams
    DATA.STREAM{i,1} = allStreams.Elements.ItemName(i-1);
end

for i=1:numStreams
    DATA.STREAM{i,2} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\TEMP_OUT\MIXED']).value; %temeperature
    DATA.STREAM{i,3} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\PRES_OUT\MIXED']).value; %pressure
    if length(components.cathode) == 2 &&  length(components.anode) == 2
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2))); char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
    elseif length(components.cathode) == 1 &&  length(components.anode) == 2
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'; char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
    elseif length(components.cathode) == 2 &&  length(components.anode) == 1
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2)))};
    elseif length(components.cathode) == 1 &&  length(components.anode) == 1
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'};
    end
    for j=1:length(temp_materials)
        MOLEFLOW{j,1} = temp_materials{j};
        MOLEFLOW{j,2} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\MOLEFLOW\MIXED\',temp_materials{j}]).value; %total moleflow
        DATA.STREAM{i,4} = MOLEFLOW;
        MASSFLOW{j,1} = temp_materials{j};
        MASSFLOW{j,2} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\MASSFLOW\MIXED\',temp_materials{j}]).value; %total moleflow
        DATA.STREAM{i,5} = MASSFLOW;
    end
    DATA.STREAM{i,6} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\VOLFLMX\MIXED']).value;  %total volume flow[m3/s]
    DATA.STREAM{i,7} = h.Tree.FindNode(['\Data\Streams\',DATA.STREAM{i,1},'\Output\RHOMX_MASS\MIXED']).value;  %mass density[kg/m3]
end

%% Unit-to-Unit connection
% structure = zeros(numUnits + 14, numUnits + 14);
% for i=1:numUnits
%     % INLET & OUTLET & SIDE STREAMS
%     iocount = 1;
%     for io = {'INL:CO2', 'INL:EL', 'INL:CH', 'SEX:A', 'SEX:C', 'PUR:A:CH', 'PUR:C:EL', 'PUR:CO2',...
%             'OUT:C:G','OUT:C:L','OUT:A:G','OUT:A:L','S12-EX', 'S15-EX'}
%         if sum(strcmp({DATA.UNIT{i,14}{1,:}},io)) ~= 0
%             temp = strcmp({DATA.STREAM{:,1}}, io);
%             if iocount<=5
%                 structure(numUnits+iocount, i) = sum([DATA.STREAM{temp,4}{:,2}]);
%             else
%                 structure(i,numUnits+iocount) = sum([DATA.STREAM{temp,4}{:,2}]);
%             end
%         end
%         iocount=iocount+1;
%     end
%     
%     for j=1:numUnits
%         for k = {DATA.UNIT{i,14}{1,:}} % 특정 유닛에 연결되어 있는 stream 이름 목록에 대해서
%             if sum(strcmp(k, {DATA.UNIT{j,14}{1,:}}))~=0 && ... % Unit i에 대해 연결되어 있는 Unit j 인데 i에 IN이 없고 j에는 OUT이 없는 조건에 대해서
%                     isempty(strfind(DATA.UNIT{i,14}{2,strcmp(k, {DATA.UNIT{i,14}{1,:}})},'IN')) && isempty(strfind(DATA.UNIT{j,14}{2,strcmp(k, {DATA.UNIT{j,14}{1,:}})},'OUT'))
%                 if structure(i,j)==0 % 중첩을 막고자 1번 있으면 실행 후 비활성화
%                     temp = strcmp(DATA.UNIT{j,14}{1,strcmp(k, {DATA.UNIT{j,14}{1,:}})},  {DATA.STREAM{:,1}});
%                     structure(i,j) = sum([DATA.STREAM{temp,4}{:,2}]); % connection이 같은게 있으면 moleflow 만큼으로 weight를 주는 digraph 생성
%                 else
%                 end
%             end
%         end
%     end
% end

%% Directed Graph Reconstruction
% node = {DATA.UNIT{:,1}, 'INL:CO2', 'INL:EL', 'INL:CH', 'SEX:A', 'SEX:C', 'PUR:A:CH', 'PUR:C:EL', 'PUR:CO2',...
%     'OUT:C:G','OUT:C:L','OUT:A:G','OUT:A:L','S12-EX', 'S15-EX'};
% G = digraph(structure,node,'OmitSelfloops');
% LWidths = 10*G.Edges.Weight/max(G.Edges.Weight);
% p = plot(G,'Layout','force','LineWidth',LWidths);
% highlight(p,[1 2 3],'NodeColor','g');                                      %inlet
% highlight(p,[25 26 27 28],'NodeColor','magenta');                          %outlet
% highlight(p,[8 9],'NodeColor','red','Marker','s','MarkerSize',12);         %Reactor

%% Cell to Table
DATA.STREAM = cell2table(DATA.STREAM,...
    'VariableNames',{'NAME' 'TEMPERATURE' 'PRESSURE' 'MOLEFLOW' ' MASSFLOW' 'VOLFLOW' 'DENSITY'});
DATA.UNIT = cell2table(DATA.UNIT,...
    'VariableNames',{'NAME' 'TEMPERATURE' 'PRESSURE' 'HEATDUTY' 'CONDDUTY' 'REBDUTY' 'WORK' 'MOLEFLOW_IN' 'MOLEFLOW_OUT' 'MASSFLOW_IN' 'MASSFLOW_OUT' 'ENTH_IN' 'ENTH_OUT' 'CONNECTION' 'UNIT_NAME'});
