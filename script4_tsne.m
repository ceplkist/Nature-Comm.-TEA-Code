%%
clear all
clc
load RESULT.mat
load materials.mat

%%
for haha=1:288
DATA = RESULT{haha,4};
DATA.UNIT = table2cell(DATA.UNIT);
DATA.STREAM = table2cell(DATA.STREAM);
numUnits = size(DATA.UNIT,1);
% Unit-to-Unit connection
structure = zeros(numUnits + 14, numUnits + 14);

for i=1:numUnits
    % INLET & OUTLET & SIDE STREAMS
    iocount = 1;
    for io = {'INL:CO2', 'INL:EL', 'INL:CH', 'SEX:A', 'SEX:C', 'PUR:A:CH', 'PUR:C:EL', 'PUR:CO2',...
            'OUT:C:G','OUT:C:L','OUT:A:G','OUT:A:L','S12-EX', 'S15-EX'}
        if sum(strcmp({DATA.UNIT{i,14}{1,:}},io)) ~= 0
            temp = strcmp({DATA.STREAM{:,1}}, io);
            if iocount<=5
                structure(numUnits+iocount, i) = sum([DATA.STREAM{temp,5}{:,2}]);
            else
                structure(i,numUnits+iocount) = sum([DATA.STREAM{temp,5}{:,2}]);
            end
        end
        iocount=iocount+1;
    end
    
    for j=1:numUnits
        for k = {DATA.UNIT{i,14}{1,:}} % 특정 유닛에 연결되어 있는 stream 이름 목록에 대해서
            if sum(strcmp(k, {DATA.UNIT{j,14}{1,:}}))~=0 && ... % Unit i에 대해 연결되어 있는 Unit j 인데 i에 IN이 없고 j에는 OUT이 없는 조건에 대해서
                    isempty(strfind(DATA.UNIT{i,14}{2,strcmp(k, {DATA.UNIT{i,14}{1,:}})},'IN')) && isempty(strfind(DATA.UNIT{j,14}{2,strcmp(k, {DATA.UNIT{j,14}{1,:}})},'OUT'))
                if structure(i,j)==0 % 중첩을 막고자 1번 있으면 실행 후 비활성화
                    temp = strcmp(DATA.UNIT{j,14}{1,strcmp(k, {DATA.UNIT{j,14}{1,:}})},  {DATA.STREAM{:,1}});
                    structure(i,j) = sum([DATA.STREAM{temp,5}{:,2}]); % connection이 같은게 있으면massflow 만큼으로 weight를 주는 digraph 생성
                else
                end
            end
        end
    end
end

% % Directed Graph Reconstruction
% node = {DATA.UNIT{:,1}, 'INL:CO2', 'INL:EL', 'INL:CH', 'SEX:A', 'SEX:C', 'PUR:A:CH', 'PUR:C:EL', 'PUR:CO2',...
%     'OUT:C:G','OUT:C:L','OUT:A:G','OUT:A:L','S12-EX', 'S15-EX'};
% G = digraph(structure,node,'OmitSelfloops');
% LWidths = 10*G.Edges.Weight/max(G.Edges.Weight);
% p = plot(G,'Layout','force','LineWidth',LWidths);
% highlight(p,[1 2 3],'NodeColor','g');                                      %inlet
% highlight(p,[25 26 27 28],'NodeColor','magenta');                          %outlet
% highlight(p,[8 9],'NodeColor','red','Marker','s','MarkerSize',12);         %Reactor

   unitList = {'COMP:C','COMP:C2','HEAT:C','HEAT:C2','HEAT:C3','HEAT:C4','MIX:A:CT','MIX:A:EL',...
        'MIX:C:EL','MIX:CH','MIX:CO2','PSA1:C','PSA2:C','REC:A:CH','REC:C:EL','REC:CO2','RXN:A','RXN:A-1','RXN:A-2',...
        'RXN:C','RXN:C-2','RXN:C-3','SEP:A:CT','SEP:A:EX','SEP:A:GL','SEP:A:LL','SEP:C:EX','SEP:C:GG','SEP:C:GL','SEP:C:LL','SPL:EL'};
 countf1=1; 
    for f1=unitList
        countf2=1;
        for f2=unitList
            
            aa=strcmp({DATA.UNIT{:,1}},f1);
            bb=strcmp({DATA.UNIT{:,1}},f2);
            if isempty(structure(aa,bb))
                new_structure(countf1,countf2) = 0;
            else
                new_structure(countf1,countf2) = structure(aa,bb);
            end
            countf2=countf2+1;
            
            
        end
        countf1=countf1+1;
    end


struc_tsne{haha} = new_structure;
end

%% extract input for tsme
%%
count = 1;
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
for i=1:16
    for j=1:18        
        DATA=RESULT{(i-1)*18+j,4};
        Name_CATHODE(count) = materials.name(CathodeCandidate(i));
        Name_ANODE(count) = materials.name(AnodeCandidate(j));
        Phase_CATHODE(count) = materials.phase(CathodeCandidate(i));
        Phase_ANODE(count) = materials.phase(AnodeCandidate(j));
        Phase_Process{count} = [char(Phase_CATHODE(count)) char(Phase_ANODE(count))];
        COST(count) = DATA.optimization(1,1);
        NPV(count)  = DATA.NPV;
        
        
        MarketCost_CATHODE(count) =  materials.price(CathodeCandidate(i));
        MarketCost_ANODE(count) = materials.price(AnodeCandidate(j));
        NPV_TOTAL(count) = DATA.NPV;
        
        C = MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2)/...
            (DATA.optimization(1,1)+MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2));
        LevelizedCostRatio_CATHODE(count) =  DATA.optimization(1,1)*C;
        LevelizedCostRatio_ANODE(count) =  DATA.optimization(2,2)*(1-C);
        LevelizedCost_CATHODE(count) =  DATA.optimization(1,1);
        LevelizedCost_ANODE(count) =  DATA.optimization(2,2);
               
%         Phase_Process{count} = char(strjoin([char(Phase_CATHODE(count)) char(Phase_ANODE(count)) Name_CATHODE(count)],''));
        count = count+1;
    end
end

%% post-processing
for i=1:size(struc_tsne,2)
X(i,:) = [reshape(struc_tsne{1,i},1,[])];
end
NPV = (NPV-min(NPV))./(max(NPV)-min(NPV));
% rng default % for reproducibility
% [Y,loss] = tsne(X,'Algorithm','exact','Distance','mahalanobis');
% figure(1)
% gscatter(Y(:,1),Y(:,2),Phase_Process')
rng default % for reproducibility
[Y,loss] = tsne(X,'Algorithm','exact','Distance','cosine');
figure(2)
gscatter(Y(:,1),Y(:,2),Phase_Process')
rng default % for reproducibility
[Y,loss] = tsne(X,'Algorithm','exact','Distance','chebychev');
figure(3)
gscatter(Y(:,1),Y(:,2),Phase_Process')
rng default % for reproducibility
[Y,loss] = tsne(X,'Algorithm','exact','Distance','euclidean');
figure(4)
gscatter(Y(:,1),Y(:,2),Phase_Process')



    
    


