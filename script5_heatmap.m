% clear all;
clc;
load RESULT
load materials.mat
CathodeCandidate = [1 3 4 5 6 7 8 9 10 12 13 14 15 16 17 18];
AnodeCandidate = [19 20 21 22 23 24 25 26 27 28 29 30 31 34 36 37 38 39];
count = 1;
for i=1:16
    for j=1:18        
        try
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
        
        LCCoverMC(i,j) = DATA.optimization(1,1)*C/materials.price(CathodeCandidate(i));
        
               
%         Phase_Process{count} = char(strjoin([char(Phase_CATHODE(count)) char(Phase_ANODE(count)) Name_CATHODE(count)],''));
        
        count = count+1;
        catch
            count=count+1
        end
    end
end

set(gcf,'position',[10 10 500 600])
imagesc(LCCoverMC(2:end,2:end))
axis square
axis off
% yticks(linspace(1,15,15))
% xticks(linspace(1,17,17))
% xticklabels(xname);
% xtickangle(90)
% yticklabels(yname);
% title('NPV')
% colorbar
set(gcf, 'PaperPositionMode','auto');
figname='NPV';
print('-dpng',figname,'-r300');