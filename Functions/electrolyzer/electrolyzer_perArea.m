function [ProductionRate,Area,Conversion] = electrolyzer(Efficiency, CurrentDensity, potential, materials, components, input)
%%electrolyzer model
%   7/19/2018 Jonggeol Na


% ----------------------------input---------------------------------------
% Efficiency.panel : solar PV panel efficiency (~17%)
% Efficiency.ratio : PV operating time per day time (~20%)
% Efficiency.FaradayEfficiency.cathode: Faraday efficiency 1xn (1-18)
% Efficiency.FaradayEfficiency.anode: Faraday efficiency 1xm (19-29)

% CurrentDensity: Current density of cell                                  [mA/cm^2]

% materials: materials.mat is the overall database prepared by Jonggeol Na

% potential: total potential included over-potential                       [V]

% components.cathode: 1xn (1-18)
% components.anode  : 1xm (19-29)

% input.Solar: Total solar energy from sun                                 [Wh/m^2/day]
% input.CO2  : one pass CO2 inlet flow rate                                [mol/s]
% input.PV   : PV farm generator capacity                                  [MW]

% example
% input.PV = 40;
% input.CO2 = 100;
% input_Solar = 5.41*1000;
% input.Solar = 5.41*1000;
% Efficiency.panel = 0.17;
% Efficiency.ratio = 0.2;
% Efficiency.FaradayEfficiency.cathode = 1;
% Efficiency.FaradayEfficiency.cathode = [0.1 0.9];
% Efficiency.FaradayEfficiency.anode = [1];
% CurrentDensity = 300;
% components.cathode = [1 3]; 
% components.anode = [19];    
% potential =3.5;

% ----------------------------output---------------------------------------
%ProductionRate: chemical production rate                                  [mol/s]
%Area          : electrolyzer and panel area                               [m^2]
%Conversion    : one pass CO2 conversion                                   [-]
% -------------------------------------------------------------------------
%% Error Check

if potential < max(materials.standard_potential(components.cathode))+max(materials.standard_potential(components.anode))
    disp('error: potential is not enough to react');
    return
else
end

%% Main Script
% materials       =  table2struct(materials);
FaradayConstant =  96485.3329;                                             %Faraday constant (C/mol)

% Cathode product production rate
for i = 1:length(components.cathode)
    ProductionRate.cathode(i)  =  CurrentDensity*10^-3/FaradayConstant/...
        materials.z(components.cathode(i))*...
        Efficiency.FaradayEfficiency.cathode(i);                           %mol/s/cm^2
end

% Anode product production rate
for i = 1:length(components.anode)
    ProductionRate.anode(i)  =  CurrentDensity*10^-3/FaradayConstant/...
        materials.z(components.anode(i))*...
        Efficiency.FaradayEfficiency.anode(i);                             %mol/s/cm^2
end



%averaged by sunlight time
EnergyPanel     =  input.PV*10^6*Efficiency.ratio;                         %energy after PV farm  [Watt]
EnergySolar     =  EnergyPanel/Efficiency.panel;                           %necessary solar energy[Watt]
Area.Panel      =  EnergySolar*24/input.Solar;                             %Area of the PV panel[m^2]
EnergyCell      =  CurrentDensity*potential;                               %energy consumed by electrochemical cell [mWatt/cm^2]
Area.Cell       =  EnergyPanel/(EnergyCell/10^3)/10^4;                     %Area of the electrochemical cell [m^2]


% ProductionRate.cathode  =  ProductionRate.cathode;%Area.Cell*10^4;          %[mol/s]
% ProductionRate.anode    =  ProductionRate.anode;%Area.Cell*10^4;            %[mol/s]
Conversion              =  dot(ProductionRate.cathode,...
materials.carbon(components.cathode))/input.CO2;                       %[-]




end

