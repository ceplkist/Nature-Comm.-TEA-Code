function [G,process,h] = gen_process(materials,superstructure, components, cascade,batch_num,NAME)
%% Techno-economic Analysis for Electrochemical Processes
% gen_process.m
%
% Initial formulation of superstructure for selected production systems.
% Function automatically generate process structure
%
%
% 2018 Jonggeol Na
% -------------------------------------------------------------------------
% 07/20/2018 first version
% - autonomous process structure generation based on pre-formulated
% superstructure
% - digraph plot of process structure
%
% 07/25/2018 update
% - autonomous aspen file generation
% ------------------------------input--------------------------------------%
% materials: materials.mat is the overall database prepared by Jonggeol Na
% superstructure: superstructure.mat is the superstructure of e-chemical
% process prepared by Jonggeol Na
% components.cathode: 1xn (1-18)   ex) [1 3 6] --> hydrogen+CO+methane
% components.anode  : 1xm (19-29)  ex) [19 24] --> O2 + FDCA
% cascade: existence of cascade strucutre (cathode output -> anode input)
%
%  CATHODE PRODUCT
% 1	hydrogen
% 2	syngas
% 3	carbon monoxide
% 4	formate
% 5	methanol
% 6	methane
% 7	ethylene
% 8	ethanol
% 9	n-propanol
% 10	acetaldehyde
% 11	glyoxal
% 12	hydroxyacetone (acetol)
% 13	acetone
% 14	acetate
% 15	Allyl alcohol
% 16	glycolaldehyde
% 17	propionaldehyde
% 18	ethylene glycol
%  ANODE PRODUCT
% 19	oxygen
% 20	acetic acid/acetate
% 21	benzoic acid
% 22	2-furoic acid (from furfural)
% 23	2-furoic acid (from furfuryl alcohol)
% 24	2,5-furandicarboxylic acid
% 25	4-methoxybenzaldehyde
% 26	acetophenone
% 27	acetone
% 28	nitrogen + CO2
% 29	phenoxyacetic acid
% 30	formate
% ------------------------------output-------------------------------------
% G: process system graph
% structure: structure matrix
% h: Aspen plus handle
% -------------------------------------------------------------------------
%% Initial processing
pfad = [pwd,'\Functions\ASPEN_FILE\',num2str(batch_num),'\basefile_include_reactor_PR.bkp']     ;               %Aspen file diRECtory
process.structure = superstructure;                                                %initial structure
process.names = {'INL:CO2','INL:EL','INL:CH',...
    'MIX:CO2','MIX:C:EL','MIX:A:EL','MIX:CH',...
    'RXN:C','RXN:A',...
    'SEP:C:GL','SEP:C:GG','SEP:C:LL',...
    'SEP:A:GL','SEP:A:GG','SEP:A:LL',...
    'REC:CO2','REC:C:EL','REC:A:EL','REC:A:CH','REC:COP',...
    'PUR:CO2','PUR:C:EL','PUR:A:EL','PUR:A:CH',...
    'OUT:C:G','OUT:C:L','OUT:A:G','OUT:A:L'};
process.types = {'stream','stream','stream',...
    'block','block','block','block',...
    'block','block',...
    'block','block','block',...
    'block','block','block',...
    'block','block','block','block','block',...
    'stream','stream','stream','stream',...
    'stream','stream','stream','stream'};
process.mapping = {'MATERIAL','MATERIAL','MATERIAL',...
    'MIXER','MIXER','MIXER','MIXER',...
    'RSTOIC','RSTOIC',...
    'FLASH2','SEP','DISTL',...
    'FLASH2','SEP','DISTL',...
    'FSPLIT','FSPLIT','FSPLIT','FSPLIT','FSPLIT',...
    'MATERIAL','MATERIAL','MATERIAL','MATERIAL',...
    'MATERIAL','MATERIAL','MATERIAL','MATERIAL'};

Cathode_Product = materials.name(components.cathode);
Anode_Product   = materials.name(components.anode);

% disp(table(Cathode_Product)); disp(table(Anode_Product));
% fprintf('cascade activation: %d \n',cascade);

%% Calculate the superstructure matrix

%Cathode
if sum(eq(materials.phase(components.cathode),'g')) == 0                   %Type I: if there is no gas == only liquid products
    process.structure(11,:) = 0;
    process.structure(:,11) = 0;
    
    process.structure(25,:) = 0;
    process.structure(:,25) = 0;
    
    process.structure(10,17)= 0;
    
elseif sum(eq(materials.phase(components.cathode),'l')) == 0               %Type II: if there is no liquid == only gas products
    process.structure(12,:) = 0;
    process.structure(:,12) = 0;
    
    process.structure(20,:) = 0;
    process.structure(:,20) = 0;
    
    process.structure(26,:) = 0;
    process.structure(:,26) = 0;
    
    process.structure(10,16)= 0;
else                                                                       %Type III: gas+liquid products
    process.structure(10,17)= 0;
    
    process.structure(10,16)= 0;
end

%Anode
if sum(eq(materials.phase(components.anode),'g')) == 0                     %Type I: if there is no gas == only liquid products
    process.structure(13,:) = 0;
    process.structure(:,13) = 0;
    
    process.structure(14,:) = 0;
    process.structure(:,14) = 0;
    
    process.structure(18,:) = 0;
    process.structure(:,18) = 0;
    
    process.structure(27,:) = 0;
    process.structure(:,27) = 0;
    
    
elseif sum(eq(materials.phase(components.anode),'l')) == 0                 %if there is no liquid == only gas products
    %     if components.anode == 19                                               %Type II: O2
    process.structure(14,:) = 0;
    process.structure(:,14) = 0;
    
    process.structure(15,:) = 0;
    process.structure(:,15) = 0;
    
    process.structure(28,:) = 0;
    process.structure(:,28) = 0;
    
    process.structure(19,:) = 0;
    process.structure(:,19) = 0;
    
    process.structure(3,:)  = 0;
    process.structure(:,3)  = 0;
    
    process.structure(7,:)  = 0;
    process.structure(:,7)  = 0;
    
    %     else                                                                   %Type III: CO2, N2, O2
    %         process.structure(28,:) = 0;
    %         process.structure(:,28) = 0;
    %
    %         process.structure(13,27)= 0;
    %
    %         process.structure(13,18) = 0;
    %         process.structure(9,15) = 0;
    
    
    %     end
    
else                                                                       %gas+liquid products
    %     if components.anode == 19                                               %Type IV: O2
    process.structure(14,:) = 0;
    process.structure(:,14) = 0;
    
    process.structure(18,:) = 0;
    process.structure(:,18) = 0;
    
    process.structure(13,18)= 0;
    process.structure(9,15) = 0;
    
    %     else                                                                   %Type V: CO2, N2, O2
    %         process.structure(13,18) = 0;
    %         process.structure(13,27) = 0;
    %         process.structure(9,15)  = 0;
    %
    %     end
end

%Cathode->anode cascade production
if sum(components.cathode == 5) ~=0 && sum(components.anode == 36) ~=0 ||...
        sum(components.cathode == 5) ~=0 && sum(components.anode == 37) ~=0 ||...
        sum(components.cathode == 8) ~=0 && sum(components.anode == 21) ~=0 ||...
        sum(components.cathode == 8) ~=0 && sum(components.anode == 22) ~=0 ||...
        sum(components.cathode == 8) ~=0 && sum(components.anode == 23) ~=0 ||...
        sum(components.cathode == 18) ~=0 && sum(components.anode == 38) ~=0 ||...
        sum(components.cathode == 18) ~=0 && sum(components.anode == 39) ~=0
    
    if cascade == 1                                                        %only for methanol and ethanol
        process.structure(12,26) = 0;
    else
        process.structure(20,:) = 0;
        process.structure(:,20) = 0;
    end
else
    process.structure(20,:) = 0;
    process.structure(:,20) = 0;
end
process.order.in     = sum(process.structure,1);
process.order.out    = sum(process.structure,2)';

%% digraph structure

G = digraph(process.structure,process.names,'OmitSelfLoops');
% p = plot(G,'Layout','force');
% highlight(p,[1 2 3],'NodeColor','g');                                      %inlet
% highlight(p,[25 26 27 28],'NodeColor','magenta');                          %outlet
% highlight(p,[8 9],'NodeColor','red','Marker','s','MarkerSize',12);         %Reactor
% drawnow
%% Pre-processing for generating aspen plus file
filename = strjoin([NAME,'.bkp'],'');
try
    h = actxserver('Apwn.Document');                                           %active X handle
    invoke(h,'InitFromArchive2', pfad);
catch
    pause(5)
    h = actxserver('Apwn.Document');                                           %active X handle
    invoke(h,'InitFromArchive2', pfad);
end
% h.SaveAs(filename) ;                                                       % saves the current file. Thus, the original(base) file remains unchanged even in case of a fatal error during execution.
blocknode = h.Tree.FindNode('\Data\Blocks');                               %Block nodes
streamnode = h.Tree.FindNode('\Data\Streams\');                            %stream nodes
% set(h, 'Visible', 0);

%% unit blocks generation
for i =1:length(process.names)
    if process.order.in(i) + process.order.out(i) ~= 0 && strcmp(process.types{i},'block')...
            &&i~=8 && i~=9                                                 %Pre-defined Reactor
        
        % Liquid/Liquid separation (distillation & extraction)
        if i==12
            if materials.type(components.cathode(2)) == 1                  %Type 1 - distl
                if components.cathode(2) == 5 ||  components.cathode(2) == 10 || components.cathode(2) == 13   % only for methanol
                    blocknode.Elements.Add('SEP:C:LL!RADFRAC');
                else
                    blocknode.Elements.Add('SEP:C:LL!DISTL');
                end
                
            elseif materials.type(components.cathode(2)) == 2              %Type 2 - sep - distl
                blocknode.Elements.Add('SEP:C:EX!SEP');
                blocknode.Elements.Add('SEP:C:LL!DISTL');
            end
            
            
            
        elseif i==15
            if materials.type(components.anode(2)) == 1                    %Type 1 - distl
                blocknode.Elements.Add('SEP:A:LL!DISTL');
            elseif materials.type(components.anode(2)) == 2                %Type 2 - sep - distl
                blocknode.Elements.Add('SEP:A:EX!SEP');
                blocknode.Elements.Add('SEP:A:LL!DISTL');
            end
            
        else
            %The Others
            temp = [process.names{i},'!',process.mapping{i}];
            blocknode.Elements.Add(temp);
        end
        
        % PSA
        if i== 11
            if sum(eq(materials.phase(components.cathode),'g')) == 1       % H2 is the only gas
                
            else
                blocknode.Elements.Add('PSA1:C!PSA1');
                blocknode.Elements.Add('PSA2:C!PSA2');
                blocknode.Elements.Add('HEAT:C!HEATER');
                blocknode.Elements.Add('HEAT:C2!HEATER');
                blocknode.Elements.Add('COMP:C!COMPR');
                blocknode.Elements.Add('COMP:C2!COMPR');
                blocknode.Elements.Add('HEAT:C3!HEATER');
                blocknode.Elements.Add('HEAT:C4!HEATER');
            end
            %         elseif i==14
            %             blocknode.Elements.Add('PSA1:A!PSA190109');
            %             blocknode.Elements.Add('PSA2:A!PSA190109');
            %             blocknode.Elements.Add('HEAT:A!HEATER');
            %             blocknode.Elements.Add('COMP:A!COMPR');
        end
    else
    end
end

%% streams generation
for i =1:length(process.names)
    if process.order.in(i) + process.order.out(i) ~= 0 && strcmp(process.types{i},'stream')
        temp = [process.names{i},'!',process.mapping{i}];
        streamnode.Elements.Add(temp);
    else
    end
end

%% etc generation (inl:EL splitter,...)
blocknode.Elements.Add('SPL:EL!FSPLIT');                                   %inl:EL-spl:EL
streamnode.Elements.Add('EL:C');
streamnode.Elements.Add('EL:A');

%% connection - inlet stream (INL:CO2, INL:EL, INL:CH)
for i=1:3
    if process.order.in(i) + process.order.out(i) ~= 0 && strcmp(process.types{i},'stream')
        if i==2
            connection = blocknode.FindNode('SPL:EL\Ports\F(IN)');
            connection.Elements.Add('INL:EL');
            connection = blocknode.FindNode('SPL:EL\Ports\P(OUT)');
            connection.Elements.Add('EL:C');
            connection.Elements.Add('EL:A');
            temp = ['MIX:C:EL','\Ports\','F(IN)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add('EL:C');
            temp = ['MIX:A:EL','\Ports\','F(IN)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add('EL:A');
        else
            temp = [process.names{find(process.structure(i,:))},'\Ports\','F(IN)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add(process.names{i});
        end
    else
    end
end

%% connection - outlet & purge stream
%('PUR:CO2','PUR:C:EL','PUR:A:EL','PUR:A:CH','OUT:C:G','OUT:C:L','OUT:A:G',
%'OUT:A:L')
for i=21:28
    if process.order.in(i) + process.order.out(i) ~= 0 && strcmp(process.types{i},'stream')
        if strcmp(process.mapping{find(process.structure(:,i))},'FLASH2') && i==27
            temp = [process.names{find(process.structure(:,i))},'\Ports\','V(OUT)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add(process.names{i});
        elseif strcmp(process.mapping{find(process.structure(:,i))},'FLASH2') && i==28
            temp = [process.names{find(process.structure(:,i))},'\Ports\','L(OUT)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add(process.names{i});
        elseif (i==25) && (sum(eq(materials.phase(components.cathode),'g')) == 2) %PSA
            connection = blocknode.FindNode('PSA2:C\Ports\output2(OUT)');
            connection.Elements.Add(process.names{i});
            
        elseif  strcmp(process.mapping{find(process.structure(:,i))},'DISTL') && i==26 %Cathode distillation
            if materials.type(components.cathode(2)) == 1
                if components.cathode(2) == 5 ||  components.cathode(2) == 10 || components.cathode(2) == 13    % only for methanol
                    if materials.dist(components.cathode(2)) == 1
                        connection = blocknode.FindNode("SEP:C:LL\Ports\B(OUT)");
                        connection.Elements.Add(process.names{i});
                    else
                        connection = blocknode.FindNode("SEP:C:LL\Ports\VD(OUT)");
                        connection.Elements.Add(process.names{i});
                    end
                else
                    if materials.dist(components.cathode(2)) == 1
                        connection = blocknode.FindNode("SEP:C:LL\Ports\B(OUT)");
                        connection.Elements.Add(process.names{i});
                    else
                        connection = blocknode.FindNode("SEP:C:LL\Ports\D(OUT)");
                        connection.Elements.Add(process.names{i});
                    end
                end
                
            elseif materials.type(components.cathode(2)) == 2
                if materials.dist2(components.cathode(2)) == 1
                    connection = blocknode.FindNode("SEP:C:LL\Ports\B(OUT)");
                    connection.Elements.Add(process.names{i});
                else
                    connection = blocknode.FindNode("SEP:C:LL\Ports\D(OUT)");
                    connection.Elements.Add(process.names{i});
                end
                
                
            end
            
        elseif  strcmp(process.mapping{find(process.structure(:,i))},'DISTL') && i==28 %anode distillation
            if materials.type(components.anode(2)) == 1
                if materials.dist(components.anode(2)) == 1
                    connection = blocknode.FindNode("SEP:A:LL\Ports\B(OUT)");
                    connection.Elements.Add(process.names{i});
                else
                    connection = blocknode.FindNode("SEP:A:LL\Ports\D(OUT)");
                    connection.Elements.Add(process.names{i});
                end
            elseif materials.type(components.anode(2)) == 2
                if materials.dist2(components.anode(2)) == 1
                    connection = blocknode.FindNode("SEP:A:LL\Ports\B(OUT)");
                    connection.Elements.Add(process.names{i});
                else
                    connection = blocknode.FindNode("SEP:A:LL\Ports\D(OUT)");
                    connection.Elements.Add(process.names{i});
                end
            end
            
            % The others
        else
            temp = [process.names{find(process.structure(:,i))},'\Ports\','P(OUT)'];
            connection = blocknode.FindNode(temp);
            connection.Elements.Add(process.names{i});
        end
    end
end

%% connection - Block/Block inter-connection (i->j)
for i=4:20
    if process.order.out(i) ~= 0 && strcmp(process.types{i},'block')
        for j=find(process.structure(i,4:20))+3
            if  i==8                                                       %Cathode
                temp = [process.names{j},'\Ports\','F(IN)'];
                connection = blocknode.FindNode(temp);
                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                
            elseif j==9                                                    %Anode
                streamnode.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                
                temp = [process.names{i},'\Ports\','P(OUT)'];
                connection = blocknode.FindNode(temp);
                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                
                temp = ['RXN:A-1','\Ports\','F(IN)'];
                connection = blocknode.FindNode(temp);
                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
            elseif (i==11) && (sum(eq(materials.phase(components.cathode),'g')) == 2)
                %PSA
                streamnode.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                temp = [process.names{j},'\Ports\','F(IN)'];
                connection = blocknode.FindNode(temp);
                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                
                if j==16
                    temp = [process.names{i},'\Ports\','P(OUT)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                end
                if j==25
                    connection = blocknode.FindNode('PSA2:C\Ports\output2(OUT)'); %Cathode gas outlet
                    connection.Elements.Add('OUT:C:G');
                end
                
                streamnode.Elements.Add('S11-CC2');
                streamnode.Elements.Add('SCC2-HC4');
                streamnode.Elements.Add('SHC4-PC1');
                streamnode.Elements.Add('SPC1-HC2');
                streamnode.Elements.Add('SHC2-PC2');
                streamnode.Elements.Add('SPC1-H2');
                %streamnode.Elements.Add('SPC2-25');
                streamnode.Elements.Add('SPC2-HC');
                streamnode.Elements.Add('SHC-CC');
                streamnode.Elements.Add('SCC-HC3');
                streamnode.Elements.Add('SHC3-PC1');
                streamnode.Elements.Add('SS1-PC2');
                
                connection = blocknode.FindNode('SEP:C:GG\Ports\P(OUT)');
                connection.Elements.Add('S11-CC2');
                connection = blocknode.FindNode('COMP:C2\Ports\F(IN)');
                connection.Elements.Add('S11-CC2');
                
                connection = blocknode.FindNode('COMP:C2\Ports\P(OUT)');
                connection.Elements.Add('SCC2-HC4');
                connection = blocknode.FindNode('HEAT:C4\Ports\F(IN)');
                connection.Elements.Add('SCC2-HC4');
                
                connection = blocknode.FindNode('HEAT:C4\Ports\P(OUT)');
                connection.Elements.Add('SHC4-PC1');
                connection = blocknode.FindNode('PSA1:C\Ports\feed1(IN)');
                connection.Elements.Add('SHC4-PC1');
                
                connection = blocknode.FindNode('PSA1:C\Ports\feed2(IN)');
                connection.Elements.Add('SHC3-PC1');
                connection = blocknode.FindNode('PSA1:C\Ports\output2(OUT)'); %H2 outlet
                connection.Elements.Add('SPC1-H2');
                connection = blocknode.FindNode('PSA1:C\Ports\output1(OUT)'); %product rich
                connection.Elements.Add('SPC1-HC2');
                connection = blocknode.FindNode('HEAT:C2\Ports\F(IN)');
                connection.Elements.Add('SPC1-HC2');
                connection = blocknode.FindNode('HEAT:C2\Ports\P(OUT)');
                connection.Elements.Add('SHC2-PC2');
                connection = blocknode.FindNode('PSA2:C\Ports\feed1(IN)'); %product rich
                connection.Elements.Add('SHC2-PC2');
                connection = blocknode.FindNode('PSA2:C\Ports\feed2(IN)'); %Shadow
                connection.Elements.Add('SS1-PC2');
                connection = blocknode.FindNode('PSA2:C\Ports\output1(OUT)');
                connection.Elements.Add('SPC2-HC');
                connection = blocknode.FindNode('HEAT:C\Ports\F(IN)');
                connection.Elements.Add('SPC2-HC');
                connection = blocknode.FindNode('HEAT:C\Ports\P(OUT)');
                connection.Elements.Add('SHC-CC');
                connection = blocknode.FindNode('COMP:C\Ports\F(IN)');
                connection.Elements.Add('SHC-CC');
                connection = blocknode.FindNode('COMP:C\Ports\P(OUT)');
                connection.Elements.Add('SCC-HC3');
   
                connection = blocknode.FindNode('HEAT:C3\Ports\F(IN)');
                connection.Elements.Add('SCC-HC3');
                
                connection = blocknode.FindNode('HEAT:C3\Ports\P(OUT)');
                connection.Elements.Add('SHC3-PC1');
 
                
                
            else
                %FLASH2
                streamnode.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                
                if strcmp(process.mapping(i),'FLASH2') && (j==12 || j==15 || j==17 || j==18) % FLASH for liquid
                    temp = [process.names{i},'\Ports\','L(OUT)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                elseif strcmp(process.mapping(i),'FLASH2') && (j==11 || j==14 || j==16)      % FLASH for gas
                    temp = [process.names{i},'\Ports\','V(OUT)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                else
                    %DISTL
                    if strcmp(process.mapping(i),'DISTL') && (j==17)  % DISTL to electrolyte recylce(C)
                        if materials.type(components.cathode(2)) == 1      % if type 1
                            if materials.dist(components.cathode(2)) == 1  % if product is heavier than electrolyte
                                temp = [process.names{i},'\Ports\','D(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                            else
                                temp = [process.names{i},'\Ports\','B(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                            end
                        elseif materials.type(components.cathode(2)) == 2  % if type 2
                            streamnode.Elements.Add('S12-EX');
                            streamnode.Elements.Add('SEX-12');
                            streamnode.Elements.Add('SEX:C');
                            
                            temp = ['SEP:C:EX\Ports\F(IN)'];
                            connection = blocknode.FindNode(temp);
                            connection.Elements.Add(['SEX:C']);
                            
                            if materials.dist2(components.cathode(2)) == 1 % if product is heavier than extraction solvent
                                temp = [process.names{i},'\Ports\','D(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S12-EX']);
                                temp = ['SEP:C:EX\Ports\P(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                connection = blocknode.FindNode(['SEP:C:EX\Ports\P(OUT)']);
                                connection.Elements.Add(['SEX-12']);
                                
                                connection = blocknode.FindNode(['SEP:C:LL\Ports\F(IN)']);
                                connection.Elements.Add(['SEX-12']);
                                
                            else
                                temp = [process.names{i},'\Ports\','B(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S12-EX']);
                                temp = ['SEP:C:EX\Ports\P(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                connection = blocknode.FindNode(['SEP:C:EX\Ports\P(OUT)']);
                                connection.Elements.Add(['SEX-12']);
                                
                                connection = blocknode.FindNode(['SEP:C:LL\Ports\F(IN)']);
                                connection.Elements.Add(['SEX-12']);
                                
                            end
                        end
                        
                        
                        
                    elseif  strcmp(process.mapping(i),'DISTL') && (j==20) && (cascade == 1) % DISTL to Cascade
                        if materials.type(components.cathode(2)) == 1      % if type 1
                            if  components.cathode(2) == 5 ||  components.cathode(2) == 10 || components.cathode(2) == 13   % only for methanol
                                 if materials.dist(components.cathode(2)) == 1  % if product is heavier than electrolyte
                                    
                                    temp = [process.names{i},'\Ports\','B(OUT)'];
                                    connection = blocknode.FindNode(temp);
                                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                 else
                                    
                                     temp = [process.names{i},'\Ports\','VD(OUT)'];
                                    connection = blocknode.FindNode(temp);
                                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                end                                
                            else
                                if materials.dist(components.cathode(2)) == 1  % if product is heavier than electrolyte
                                    temp = [process.names{i},'\Ports\','B(OUT)'];
                                    connection = blocknode.FindNode(temp);
                                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                else
                                    temp = [process.names{i},'\Ports\','D(OUT)'];
                                    connection = blocknode.FindNode(temp);
                                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                end
                            end
                        elseif materials.type(components.cathode(2)) == 2  % if type 2
                            %                             streamnode.Elements.Add('S12-EX');
                            %                             streamnode.Elements.Add('SEX-12');
                            %
                            
                            if materials.dist2(components.cathode(2)) == 1 % if product is heavier than extraction solvent
                                temp = [process.names{i},'\Ports\','B(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                %                                 temp = [process.names{i},'\Ports\','D(OUT)'];
                                %                                 connection = blocknode.FindNode(temp);
                                %                                 connection.Elements.Add(['S12-EX']);
                                %                                 temp = ['SEP:C:EX\Ports\P(OUT)'];
                                %                                 connection = blocknode.FindNode(temp);
                                %                                 connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                %                                 connection = blocknode.FindNode(['SEP:C:EX\Ports\P(OUT)']);
                                %                                 connection.Elements.Add(['SEX-12']);
                                %
                                %                                 connection = blocknode.FindNode(['SEP:C:LL\Ports\F(IN)']);
                                %                                 connection.Elements.Add(['SEX-12']);
                                
                            else
                                temp = [process.names{i},'\Ports\','D(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                %                                 temp = [process.names{i},'\Ports\','B(OUT)'];
                                %                                 connection = blocknode.FindNode(temp);
                                %                                 connection.Elements.Add(['S12-EX']);
                                %                                 temp = ['SEP:C:EX\\Ports\P(OUT)'];
                                %                                 connection = blocknode.FindNode(temp);
                                %                                 connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                %                                 connection = blocknode.FindNode(['SEP:C:EX\Ports\P(OUT)']);
                                %                                 connection.Elements.Add(['SEX-12']);
                                %
                                %                                 connection = blocknode.FindNode(['SEP:C:LL\Ports\F(IN)']);
                                %                                 connection.Elements.Add(['SEX-12']);
                            end
                        end
                        
                    elseif strcmp(process.mapping(i),'DISTL') && (j==19) % DISTL to organics recycle(A)
                        if materials.type(components.anode(2)) == 1      % if type 1
                            if materials.dist(components.anode(2)) == 1  % if product is heavier than electrolyte
                                temp = [process.names{i},'\Ports\','D(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                            else
                                temp = [process.names{i},'\Ports\','B(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                            end
                        elseif materials.type(components.anode(2)) == 2  % if type 2
                            streamnode.Elements.Add('S15-EX');
                            streamnode.Elements.Add('SEX-15');
                            streamnode.Elements.Add('SEX:A');
                            
                            temp = ['SEP:A:EX\Ports\F(IN)'];
                            connection = blocknode.FindNode(temp);
                            connection.Elements.Add(['SEX:A']);
                            
                            if materials.dist2(components.anode(2)) == 1 % if product is heavier than extraction solvent
                                temp = [process.names{i},'\Ports\','D(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S15-EX']);
                                temp = ['SEP:A:EX\Ports\P(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                connection = blocknode.FindNode(['SEP:A:EX\Ports\P(OUT)']);
                                connection.Elements.Add(['SEX-15']);
                                
                                connection = blocknode.FindNode(['SEP:A:LL\Ports\F(IN)']);
                                connection.Elements.Add(['SEX-15']);
                            else
                                temp = [process.names{i},'\Ports\','B(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S15-EX']);
                                temp = ['SEP:A:EX\Ports\P(OUT)'];
                                connection = blocknode.FindNode(temp);
                                connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                                
                                connection = blocknode.FindNode(['SEP:A:EX\Ports\P(OUT)']);
                                connection.Elements.Add(['SEX-15']);
                                
                                connection = blocknode.FindNode(['SEP:A:LL\Ports\F(IN)']);
                                connection.Elements.Add(['SEX-15']);
                                
                            end
                        end
                    elseif strcmp(process.mapping(i),'DISTL') && (j==18) % DISTL to electrolyte recylce(A) / deactivate
                        
                        
                    else
                        temp = [process.names{i},'\Ports\','P(OUT)'];
                        connection = blocknode.FindNode(temp);
                        connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                    end
                    
                end
                
                % Port (IN)
                if strcmp(process.names{j},'SEP:C:LL') && materials.type(components.cathode(2)) == 2
                    temp = ['SEP:C:EX\Ports\','F(IN)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                elseif strcmp(process.names{j},'SEP:A:LL') && materials.type(components.anode(2)) == 2
                    temp = ['SEP:A:EX\Ports\','F(IN)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                else
                    temp = [process.names{j},'\Ports\','F(IN)'];
                    connection = blocknode.FindNode(temp);
                    connection.Elements.Add(['S',num2str(i),'-',num2str(j)]);
                end
            end
        end
    end
end

% Deactivate the liquid/liquid separation (A) to electrolyte recycle
% stream.
% streamnode.Elements.Remove('S15-18');
% h.set('visible',1)




