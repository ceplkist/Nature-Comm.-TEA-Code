%% fnc_FAST_getInputs: transform the normed input in the real range inputs
%
% Usage:
%   X = fnc_FAST_getInputs(pro, NormedX)
%
% Inputs:
%    pro                project structure
%    NormedX            normed inputs 
%
% Output:
%    X               inputs in the correct ranges
%
% ------------------------------------------------------------------------
% See also 
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 01-05-2011
% 
% History:
% 1.0  01-05-2011  First release.
%      06-01-2014  Added comments.
%%

function X = fnc_FAST_getInputs(pro, NormedX)

% get the number of the input variables
ninputs = length(pro.Inputs.pdfs);

N = size(NormedX,1);

Ranges = [];

% retrieve the ranges for all the input variables
for i=1:ninputs
    if ~isempty(strfind(func2str(pro.Inputs.pdfs{i}),'pdf_Sobol'))
        Ranges = [Ranges; pro.Inputs.pdfs{i}()];
    else
        Ranges = [Ranges; pro.Inputs.pdfs{i}(0)];
    end
end

m = zeros(1,size(NormedX,2));min(NormedX);
M = ones(1,size(NormedX,2));max(NormedX);

a = repmat(m,N,1);
b = repmat(M,N,1);

r = repmat(Ranges(:,1)',N,1);
R = repmat(Ranges(:,2)',N,1);

% map the normalized input variables into real input variables for the
% model defined in pro
X = (NormedX-a).*(R-r)./(b-a) + r;



