clear all;
clc;
load RESULT_optimal_95_2.mat
load materials.mat
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
count_unit=1;
for unit = ["electrolyzer","flash","distillation",...
        "extraction","PSA","compressor","heater"]
    disp(strjoin(['============================',unit,'============================'],''))
    count = 1;
    for i=2:16
        for j=2:18
            count_CAPEX_SENSITIVITY = 1;
            for CAPEX_RATIO = linspace(0.1,10,2)              
                DATA=RESULT{(i-1)*18+j,4};
                try
                    eval(strjoin(['DATA.CapitalCosts.',unit,'=DATA.CapitalCosts.',unit,'*CAPEX_RATIO;'],''))
                catch
                    disp('unit error');
                end
                if ~isnan(DATA.NPV)
                    cost;
                    if i == 1
                        components.cathode = [1];
                        Efficiency.FaradayEfficiency.cathode = [1];
                        COST.product.cathode = [COST.hydrogen]; %$/kg
                    else
                        components.cathode = [1 CathodeCandidate(i)];
                        Efficiency.FaradayEfficiency.cathode = [0.1 0.9];
                        COST.product.cathode = [COST.hydrogen COST.cathode]; %$/kg
                    end
                    
                    if j==1
                        components.anode = [19];
                        Efficiency.FaradayEfficiency.anode = [1];
                        COST.product.anode = [COST.oxygen]; %$/kg
                    else
                        components.anode = [19 AnodeCandidate(j)];
                        Efficiency.FaradayEfficiency.anode = [0.1 0.9];
                        COST.product.anode = [COST.oxygen COST.anode]; %$/kg
                    end
                    fun = @(x) cash_flow_levelizedcost(DATA, COST, components, x);
                    A=[]; b=[]; Aeq = [0 1]; beq = [0]; lb = [0 0]; ub = [1000 1000];
                    x0 = [50 50];
                    options = optimoptions('fmincon','Display','off','Algorithm','interior-point');
                    [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
                    DATA.optimization(1,1:2) =X;
                    DATA.optimization(1,3) =Fval;
                    % Case 2: price of cathode product (2) eq 0
                    Aeq = [1 0]; beq = [0];
                    [X,Fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,[],options);
                    DATA.optimization(2,1:2) =X;
                    DATA.optimization(2,3) =Fval;
                    RESULT{(i-1)*18+j,4}.optimization = DATA.optimization;
                end
                
                
                try
                    Name_CATHODE(count) = materials.name(CathodeCandidate(i));
                    Name_ANODE(count) = materials.name(AnodeCandidate(j));
                                      
                    MarketCost_CATHODE(count) =  materials.price(CathodeCandidate(i));
                    MarketCost_ANODE(count) = materials.price(AnodeCandidate(j));
                                        
                    C = MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2)/...
                        (DATA.optimization(1,1)+MarketCost_CATHODE(count)/MarketCost_ANODE(count)*DATA.optimization(2,2));
                    LevelizedCostRatio_CATHODE(count) =  DATA.optimization(1,1)*C;
                    LevelizedCostRatio_ANODE(count) =  DATA.optimization(2,2)*(1-C);
                    LevelizedCost_CATHODE(count) =  DATA.optimization(1,1);
                    LevelizedCost_ANODE(count) =  DATA.optimization(2,2);
                   
                    LCCoverMC_CAPEX(count_CAPEX_SENSITIVITY,1) = CAPEX_RATIO;
                    LCCoverMC_CAPEX(count_CAPEX_SENSITIVITY,2) = DATA.optimization(1,1)*C/materials.price(CathodeCandidate(i));
                    
                    count_CAPEX_SENSITIVITY = count_CAPEX_SENSITIVITY+ 1;
                    count = count+1;
                catch
                    count=count+1
                end
            end
            RESULT_CAPEX_SENSITIVITY{i,j} = LCCoverMC_CAPEX;
            disp(strjoin(['Simulation is finished for ',Name_CATHODE(count-1),' and ',Name_ANODE(count-1)],''))
        end
    end
    eval(strjoin([unit,'_CAPEX_SENSITIVITY = RESULT_CAPEX_SENSITIVITY;'],''));
    count_haha=1;
    for i=2:16
        for j=2:18
            slope(count_haha,count_unit) = (RESULT_CAPEX_SENSITIVITY{i,j}(2,2)-RESULT_CAPEX_SENSITIVITY{i,j}(1,2))...
                /(RESULT_CAPEX_SENSITIVITY{i,j}(2,1)-RESULT_CAPEX_SENSITIVITY{i,j}(1,1));
            count_haha = count_haha+1;
        end
    end
    boxplot(slope)
    drawnow
    count_unit=count_unit+1;
end

save('RESULT_localSensitivityforCAPEX_optimal.mat')
