function [G,process] = gen_process(materials,superstructure, components, cascade,batch_num,NAME)
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



