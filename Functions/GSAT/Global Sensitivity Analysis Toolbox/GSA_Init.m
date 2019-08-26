%% GSA_Init: initialize the variables used in the GSA computation
%
% Usage:
%   pro = GSA_Init(pro)
%
% Inputs:
%    pro                project structure
%
% Output:
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
% 1.0  15-01-2011  First release.
%      06-01-2014  Added comments.
%%

function pro = GSA_Init(pro)

% get two sets of samples of the input variables
[E T] = fnc_SampleInputs(pro);

pro.SampleSets.E = E;
pro.SampleSets.T = T;

% get the number of input variables
n = length(pro.Inputs.pdfs);

% set the number of possible combinations of the input variables
L = 2^n;
N = pro.N;

% prepare the structure for the evaluation of the model at the sample
% points in the set E
pro.GSA.fE = nan(N,1);

% evaluate the model at the sample points in the set E
for j=1:N
    pro.GSA.fE(j) = pro.Model.handle(pro.SampleSets.E(j,:));
end

% calculate the mean value of the model outcomes
pro.GSA.mfE = nanmean(pro.GSA.fE);

if isnan(pro.GSA.mfE)
    pro.GSA.mfE = 0;
end

% subtract the mean values from the model outcomes 
pro.GSA.fE = pro.GSA.fE - pro.GSA.mfE;

% calculate the mean values (it will be 0)
pro.GSA.f0 = nanmean(pro.GSA.fE);

% calculate the total variance of the model outcomes
pro.GSA.D  = nanmean(pro.GSA.fE.^2) - pro.GSA.f0^2;

% approximate the error of the mean value
pro.GSA.ef0 = 0.9945*sqrt(pro.GSA.D/sum(~isnan(pro.GSA.fE)));

% prepare the structures for the temporary calculations of sensitivity
% coefficients
pro.GSA.Dmi = nan(1,L-1);
pro.GSA.eDmi = nan(1,L-1);

pro.GSA.Di = nan(1,L-1);
pro.GSA.eDi = nan(1,L-1);

pro.GSA.GSI = nan(1,L-1);
pro.GSA.eGSI = nan(1,L-1);
