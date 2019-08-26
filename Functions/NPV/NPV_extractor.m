function [Cbm]=NPV_extractor(feed, solvent)
%% Reference
% Product and Process Design Principles 3rd edition, Seider et al., 
% 22.6, pg 583
% example 22.15 for rotating-disk contractor (RDC)


%% The volumetric flow rate of the feed
feed = feed * 127132.8; %1 cubic meter / second = 127 132.8 cubic feet / hour [ft3/hr]
%% The volumetric flow rate of the solvent
solvent = solvent * 127132.8; %1 cubic meter / second = 127 132.8 cubic feet / hour [ft3/hr]
%% The total volumetric flow rate through the column
total = feed + solvent; % [ft3/hr]
%% For a maximum throughput of 120 ft3/hr-ft2, cited above, the minimum
% cross sectional area for flow
cross = total/120; %[ft2]
%% Assume a throughput of 60% of the maximum value,
cross_actual = cross/0.6; %[ft2]
%% Column diameter
D = sqrt(cross_actual*4/pi); %[ft]
%% Assume an HETP of 4 ft and 6 stages, This gives a total stage height of
H = 4*6 + 3 + 3; %[ft]
%% From Table 22.32, the size factor = S = H*(D)^(1.5)
S = H*(D)^(1.5); %[ft]
%% For carbon steel at a CE index of 500, the f.o.b. purchase cost is
Cp = 317*S^0.84; % [$]
%% stainless steel construction with a material factor of 2.0 and correct for the cost index This gives an estimated f.o.b. purchase cost of
Cp = Cp*2*(550/500);
%% Bare-module cost, Cbm FBM = 4.3 for distillation column, adsorbers, absorber
Cbm = 4.3 * Cp;







