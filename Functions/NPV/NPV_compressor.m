function [cost] = NPV_compressor(W,UPF)
% Function which calculates capital compressor cost
% Input in MMBTu
% Using inlet and outlet enthalpy flow from Aspen - kJ/s
%
% INPUT
%------------------------------------------------
% Name           | Description                                | Size | 
% H2             | Enthalpy of outlet stream                  |[1x1] |
% H1             | Enthalpy of intlet stream                  |[1x1] |
% UPF            | Upscale factor                             |[1x1] |
%------------------------------------------------
%
% OUTPUT
%------------------------------------------------
% Name  | Description                                         | Size |
% cost  | upscaled capital cost of compressor in dollar       |[1x1] |
%------------------------------------------------


%Sizing
Wb = W*UPF*1e-3; %Compression duty - kW

%Cost calculation
C0 = 23000;          % [$]
S0 = 100*0.7457;       % [kW]
alpha = 0.77;
Smax = 10000*0.7457;        % maximum Size
MF1 = [3.11,3.01,2.97,2.96,2.93];

%Calculating whether Size is within Costing Range, otherwise dividing unit
%into several units
if Wb <= Smax
    Amount = 1;
    S = Wb;
else
    Amount = ceil(Wb/Smax);
    S = Wb/Amount;
end

BC = C0*(S/S0)^alpha; %Base Cost
    
MPF = 1; %Guthrie's material and pressure factor for centrifugal/motor


if BC<=2e5
    MF = MF1(1);
elseif (2e5<BC)&&(BC<=4e5)
    MF = MF1(2);
elseif (4e5<BC)&&(BC<=6e5)
    MF = MF1(3);
elseif (6e5<BC)&&(BC<=8e5)
    MF = MF1(4);
elseif (8e5<BC)&&(BC<=10e5)
    MF = MF1(5);
else
    MF = MF1(5);
    fprintf('BC out of order in compressor cost function');
end

UF = 576.1/113; %conversion of cost from time of Guthries book to present

BMC = UF*BC*(MF+MPF-1); %updated bare module cost
cost = BMC*Amount; %bare module cost for parallel compressors
end