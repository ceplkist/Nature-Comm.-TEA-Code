%% GSA_GetTotalSy_MultiOut_MultiSI: calculate the total sensitivity S of a subset of inputs
%
% Usage:
%   [Stot, eStot, pro] = GSA_GetTotalSy_MultiOut_MultiSI(pro, iset, verbose)
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
%     Stot               Total sensitiviy for the considered set
%     eStot              associated error estimation (at 50%)
%     pro                updated project structure
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
% 1.0  15-02-2011  First release.
%      06-01-2014  Added comments.
%%

function [Stot, eStot, pro] = GSA_GetTotalSy_MultiOut_MultiSI(pro, iset, verbose)
% calculate the total global sensitivity coefficient of the variable set 
% with index iset

if ~exist('verbose','var')
    verbose = 0;
else
    verbose = ~isempty(verbose) && verbose;
end

output = size(pro.GSA.fE,2);

% get the number of input variables
n = length(pro.Inputs.pdfs);

% get the indexes corresponding to the variables in iset
index = fnc_SelectInput(pro, iset);

% calculate the complementary set of the input indexes
compli = setdiff(1:n, index);

if isempty(compli)
    Stot = ones(output,1);
    eStot = zeros(output,1);
else
    % calculate the global sensitivity coefficient for the complementary
    % set of input variables
    [S, eS, pro] = GSA_GetSy_MultiOut_MultiSI(pro, compli, verbose);
    % follow by equations in 2.3, calculate the total global sensitivity
    % coefficient
    Stot = 1 - S;
    eStot = eS;
end