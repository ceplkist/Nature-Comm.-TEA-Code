%% GSA_GetSy: calculate the Sobol' sensitivity indices
%
% Usage:
%   [S eS pro] = GSA_GetSy(pro, iset, verbose)
%
% Inputs:
%    pro                project structure
%    iset               cell array or array of inputs of the considered set, they can be selected
%                       by index (1,2,3 ...) or by name ('in1','x',..) or
%                       mixed
%    verbose            if not empty, it shows the time (in hours) for
%                       finishing
%
% Output:
%    S                  sensitivity coefficient
%    eS                 error of sensitivity coefficient
%    pro                project structure
%
% ------------------------------------------------------------------------
% Citation: Cannavo' F., Sensitivity analysis for volcanic source modeling quality assessment and model selection, Computers & Geosciences, Vol. 44, July 2012, Pages 52-59, ISSN 0098-3004, http://dx.doi.org/10.1016/j.cageo.2012.03.008.
% See also
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 15-02-2011
%
% History:
% 1.0  15-04-2011  Added verbose parameter
% 1.0  15-01-2011  First release.
%      06-01-2014  Added comments.
%%

function [S eS pro] = GSA_GetSy(pro, iset, verbose)


if ~exist('verbose','var')
    verbose = 0;
else
    verbose = ~isempty(verbose) && verbose;
end

% get the indexes corresponding to the variables in iset
index = fnc_SelectInput(pro, iset);

if isempty(index)
    S = 0;
    eS = 0;
else
    S = 0;
    eS = 0;
    % number of variables in iset
    n = length(index);
    % number of possibile combinations for the n variables in iset 
    L = 2^n;
    
    if verbose
        tic
    end
    % for all the possible combinations of variables in iset
    for i=1:(L-1)
        % calculate the indexes of the variables in the i-th combination 
        ii = fnc_GetInputs(i);
        % calculate the real indexes of the variables in the i-th
        % combination
        si = fnc_GetIndex(index(ii));
        % if the part of sensitivity due to the si variables is not
        % calculated yet (useful to avoid to calculate again, saving time)
        if isnan(pro.GSA.GSI(si))
            
            %-------
            % if the part of variance in ANOVA corresponding to the si 
            % variables is not calculated yet (useful to avoid to calculate
            % again, saving time)
            if isnan(pro.GSA.Di(si))
                
                % get the indexes of the variables in the current
                % combination of the variables in the iset
                ixi = fnc_GetInputs(si);
                s = length(ixi);
                l = 2^s - 1;
                
                %======
                if isnan(pro.GSA.Dmi(si))
                    n = length(pro.Inputs.pdfs);
                    N = size(pro.SampleSets.E,1);
                    H = pro.SampleSets.E(:,:);
                    cii = fnc_GetComplementaryInputs(si, n);
                    % create the new mixed (E and T) samples to perform the 
                    % quasi-Monte Carlo algorithm (see section 2.4) 
                    H(:,cii) = pro.SampleSets.T(:,cii);
                    ff = nan(N,1);
                    
                    % calculate the elements of the summation reported in
                    % section 2.4 as I
                    for j=1:N
                        ff(j) = pro.GSA.fE(j)*(pro.Model.handle(H(j,:))-pro.GSA.mfE);
                    end
                    
                    % calculate the I value in section 2.4
                    pro.GSA.Dmi(si)  = nanmean(ff);
                    pro.GSA.eDmi(si) = 0.9945*sqrt((nanmean(ff.^2) - pro.GSA.Dmi(si)^2)/sum(~isnan(ff)));
                end
                %=======
                
                Di = pro.GSA.Dmi(si);
                eDi = pro.GSA.eDmi(si)^2;
                
                % compute the summation of the I values for all the
                % combinations of the current subset
                for j=1:(l-1)
                    sii = fnc_GetInputs(j);
                    k = fnc_GetIndex(ixi(sii));
                    s_r = s - length(sii);
                    % add the part of variance due to the j-th subset of
                    % variables or subtract it following eq. (20)
                    Di = Di + pro.GSA.Dmi(k)*((-1)^s_r);
                    eDi = eDi + pro.GSA.eDmi(k)^2;
                end
                
                % add/subtract the square of the mean value (here it's 0)
                pro.GSA.Di(si) = Di + (pro.GSA.f0^2)*((-1)^s);
                pro.GSA.eDi(si) = sqrt(eDi + 2*(pro.GSA.ef0^2));
                
                
            end
            %------
            % calculate the partial sensitivity coefficient by definition 
            pro.GSA.GSI(si) = pro.GSA.Di(si)/pro.GSA.D;
            pro.GSA.eGSI(si) = pro.GSA.GSI(si)*pro.GSA.eDi(si)/pro.GSA.D;
        end
        % sum the partial sensitivity coefficients for all the combinations
        % of the variables in iset
        S = S + pro.GSA.GSI(si);
        eS = eS + pro.GSA.eGSI(si);
        
        if verbose
            timelapse = toc;
            disp(timelapse*(L-1-i)/i/60/60);
        end
    end
end
