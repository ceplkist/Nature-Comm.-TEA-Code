function [ConvergenceState,h] = cal_process_forError_GSA(Efficiency, CurrentDensity, potential, materials, components, input, process, h, errorIndicator)
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








