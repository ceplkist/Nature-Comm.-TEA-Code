function [cost] = NPV_flash(LFlow,LDensity,VesselPressure,UPF)
if (abs(LFlow) > 0.0001)
    
    % Function which calculates capital flash cost
    % Input in SI
    %
    % INPUT
    %------------------------------------------------
    % Name           | Description                                | Size |
    % LFlow          | Liquid mass flow leaving the flash         |[1x1] |
    % LDensity       | Density of liquid flow leaving the flash   |[1x1] |
    % VesselPressure | Pressure in flash                          |[1x1] |
    % UPF            | Upscale factor                             |[1x1] |
    %------------------------------------------------
    %
    % OUTPUT
    %------------------------------------------------
    % Name  | Description                                         | Size |
    % cost  | upscaled capital cost of flash in dollar           |[1x1] |
    %------------------------------------------------
    
    %assumptions: Horizontal fabrication, L/D=4
    
    VesselPressure = VesselPressure/10^5; %Pa to bar
    LFlow = LFlow * UPF;
    
    %Cost calculation
    C0 = 690;          %[$]
    D0 = 3*0.3048;     %[m], feet -> meter: 0.3048
    Dmax = 10*0.3048;  %[m]
    L0 = 4*0.3048;     %[m]
    alpha = 0.78;
    beta = 0.98;
    LD_ratio = 4;
    FM = 1; %Material type
    
    bar_to_psig = 14.5038;
    
    UF = 576.1/113; %Update factor
    
    %Pressure Factor
    VP = VesselPressure*bar_to_psig;
    if VP<=50
        FP = 1;
    elseif 50<VP && VP<=100
        FP = 1.05;
    elseif 100<VP && VP<=200
        FP = 1.15;
    elseif 200<VP && VP<=300
        FP = 1.2;
    elseif 300<VP && VP<=400
        FP = 1.35;
    elseif 400<VP && VP<=500
        FP = 1.45;
    elseif 500<VP && VP<=600
        FP = 1.6;
    elseif 600<VP && VP<=700
        FP = 1.8;
    elseif 700<VP && VP<=800
        FP = 1.9;
    elseif 800<VP && VP<=900
        FP = 2.3;
    else
        FP = 2.3;
        fprintf('VP out of order in flash costing function');
    end
    
    V = 2*LFlow*300/LDensity; %LFlow [kg/s], LDensity [kg/m^3], V [m^3]
    D_raw = (4*V/(pi*LD_ratio))^(1/3) ; %[m]
    
    %Calculating whether Size is within Costing Range, otherwise dividing unit
    %into several units
    if D_raw <= Dmax
        Amount = 1;
        D = D_raw;
    else
        Amount = ceil(D_raw/Dmax);
        D = D_raw/Amount;
    end
    
    L = D*LD_ratio;
    
    BC = C0*((L/L0)^alpha)*((D/D0)^beta);
    
    %Module factor
    if BC<=2e5
        MF = 3.18;
    elseif 2e5<BC && BC<=4e5
        MF = 3.06;
    elseif 4e5<BC && BC<=6e5
        MF = 3.01;
    elseif 6e5<BC && BC<=8e5
        MF = 2.99;
    elseif 8e5<BC && BC<=10e5
        MF = 2.96;
    else
        MF = 2.96;
        fprintf('BC out of order in flash costing function');
    end
    
    MPF = FM*FP; %Material and pressure factor
    BMC = UF*BC*(MF+MPF-1); %updated bare module cost
    cost = BMC*Amount;
    
else
    cost = 0.0 ;
end

end