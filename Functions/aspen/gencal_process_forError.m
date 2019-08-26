function [ConvergenceState,h] = gencal_process_forError(Efficiency, CurrentDensity, potential, materials, components, input, process, h, errorIndicator)
%% Techno-economic Analysis for Electrochemical Processes
% gencal_process_forError.m
%
% Flowsheet regeneration for distl error flowsheet because of liquid
% products evaporate to gas line at the flash drum
% Also, recalculate the flowsheet
%
%
% 2018 Jonggeol Na
% ------------------------------output-------------------------------------
% ConcergenceState: Convergence check
% h: Aspen plus handle
% -------------------------------------------------------------------------
%% Initial processing


%% Delete the original blocks and streams
blocknode = h.Tree.FindNode('\Data\Blocks');                               %Block nodes
streamnode = h.Tree.FindNode('\Data\Streams\');                            %stream nodes

% Cathode
if errorIndicator(1)
    streamnode.Elements.Remove('OUT:C:G');
    streamnode.Elements.Remove('S10-12');
end


% Anode
if errorIndicator(2)
    streamnode.Elements.Remove('OUT:A:G');
    streamnode.Elements.Remove('S13-15');
end

%% Add the new blocks and streams and connection
% Cathode
if errorIndicator(1)
    blocknode.Elements.Add('SEP:C:CT!FLASH2'); %Cold Trap
    blocknode.Elements.Add('MIX:C:CT!MIXER'); %Cold Trap mixer
    
    streamnode.Elements.Add('OUT:C:G');
    streamnode.Elements.Add('S10-12');
    
    streamnode.Elements.Add('SGL-CT:C');
    streamnode.Elements.Add('SCT-MX:C');
    streamnode.Elements.Add('SGL-MX:C');
    
    % connection
    connection = blocknode.FindNode('SEP:C:GG\Ports\P(OUT)');
    connection.Elements.Add('SGL-CT:C');
    connection = blocknode.FindNode('SEP:C:CT\Ports\F(IN)');
    connection.Elements.Add('SGL-CT:C');
    connection = blocknode.FindNode('SEP:C:CT\Ports\V(OUT)');
    connection.Elements.Add('OUT:C:G');
    connection = blocknode.FindNode('SEP:C:CT\Ports\L(OUT)');
    connection.Elements.Add('SCT-MX:C');
    connection = blocknode.FindNode('SEP:C:GL\Ports\L(OUT)');
    connection.Elements.Add('SGL-MX:C');
    connection = blocknode.FindNode('MIX:C:CT\Ports\F(IN)');
    connection.Elements.Add('SGL-MX:C');
    connection.Elements.Add('SCT-MX:C');
    
    connection = blocknode.FindNode('MIX:C:CT\Ports\P(OUT)');
    connection.Elements.Add('S10-12');
    
    if materials.type(components.cathode(2)) == 1
        
        connection = blocknode.FindNode('SEP:C:LL\Ports\F(IN)');
        connection.Elements.Add('S10-12');
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\TOTAL").value = 'S10-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\PROD").value = 'S10-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_BLOCK\DF").value = 'SEP:C:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\DF").value = 'D:F';
        
        
    elseif materials.type(components.cathode(2)) == 2
        
        connection = blocknode.FindNode('SEP:C:EX\Ports\F(IN)');
        connection.Elements.Add('S10-12');
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\TOTAL").value = 'SEX-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\PROD").value = 'SEX-12';
        
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_BLOCK\DF").value = 'SEP:C:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\DF").value = 'D:F';
        if materials.dist2(components.cathode(2)) == 0 % dist2 == 0 (product is lighter than MTBE)
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        else
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = 'METHY-02';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        end
    end
    
end


% Anode
if errorIndicator(2)
    blocknode.Elements.Add('SEP:A:CT!FLASH2'); %Cold Trap
    blocknode.Elements.Add('MIX:A:CT!MIXER'); %Cold Trap mixer
    
    streamnode.Elements.Add('OUT:A:G');
    streamnode.Elements.Add('S13-15');
    
    streamnode.Elements.Add('SGL-CT:A');
    streamnode.Elements.Add('SCT-MX:A');
    streamnode.Elements.Add('SGL-MX:A');
    
    % connection
    connection = blocknode.FindNode('SEP:A:GL\Ports\V(OUT)');
    connection.Elements.Add('SGL-CT:A');
    connection = blocknode.FindNode('SEP:A:CT\Ports\F(IN)');
    connection.Elements.Add('SGL-CT:A');
    connection = blocknode.FindNode('SEP:A:CT\Ports\V(OUT)');
    connection.Elements.Add('OUT:A:G');
    connection = blocknode.FindNode('SEP:A:CT\Ports\L(OUT)');
    connection.Elements.Add('SCT-MX:A');
    connection = blocknode.FindNode('SEP:A:GL\Ports\L(OUT)');
    connection.Elements.Add('SGL-MX:A');
    connection = blocknode.FindNode('MIX:A:CT\Ports\F(IN)');
    connection.Elements.Add('SGL-MX:A');
    connection.Elements.Add('SCT-MX:A');
    
    connection = blocknode.FindNode('MIX:A:CT\Ports\P(OUT)');
    connection.Elements.Add('S13-15');
    
    if materials.type(components.anode(2)) == 1
        connection = blocknode.FindNode('SEP:A:LL\Ports\F(IN)');
        connection.Elements.Add('S13-15');
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\TOTAL").value = 'S13-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\PROD").value = 'S13-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.anode(2)));
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_BLOCK\DF").value = 'SEP:A:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\DF").value = 'D:F';
    elseif materials.type(components.anode(2)) == 2
        connection = blocknode.FindNode('SEP:A:EX\Ports\F(IN)');
        connection.Elements.Add('S13-15');
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\TOTAL").value = 'SEX-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\PROD").value = 'SEX-15';
        
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_BLOCK\DF").value = 'SEP:A:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\DF").value = 'D:F';
        
        if materials.dist2(components.anode(2)) == 0 % dist2 == 0 (product is lighter than MTBE)
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.anode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        else
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = 'METHY-02';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        end
    end
end

%% New operation conditions

% Cathode
if errorIndicator(1)
    h.Tree.FindNode("\Data\Blocks\SEP:C:CT\Input\TEMP").value = 253.15;% [K] -20µµ·Î ³Ã°¢
    h.Tree.FindNode("\Data\Blocks\SEP:C:CT\Input\PRES").value = input.pressure;   % [Pa]
end
% Anode
if errorIndicator(2)
    h.Tree.FindNode("\Data\Blocks\SEP:A:CT\Input\TEMP").value = 253.15;% [K] -20µµ·Î ³Ã°¢
    h.Tree.FindNode("\Data\Blocks\SEP:A:CT\Input\PRES").value = input.pressure;   % [Pa]
end
% New condition
if length(components.cathode) == 2
if components.cathode(2) == 5 || components.cathode(2) == 10 || components.cathode(2) == 13 % only for methanol
    h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_STAGE\S10-12").value = 5;
    h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL*1.1      ';
end
end

try
    %% Initialize the Aspen simulation
    h.Reinit
    %% Run the Aspen simulation
    h.Engine.Run2;
    %% Convergence check
    ConvergenceState=h.Tree.FindNode("\Data\Results Summary\Run-Status\Output\UOSSTAT2").value;
catch
    
    %% Initialize the Aspen simulation
    h.Reinit
    %% Run the Aspen simulation
    h.Engine.Run2;
    %% Convergence check
    h.SaveAs('Error.bkp');
    ConvergenceState=h.Tree.FindNode("\Data\Results Summary\Run-Status\Output\UOSSTAT2").value;
end








