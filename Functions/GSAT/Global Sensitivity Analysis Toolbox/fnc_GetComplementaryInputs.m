%% fnc_GetComplementaryInputs: give the vector of the complementary inputs
%%                                   corresponding to the index i 
%
% Usage:
%   cii = fnc_GetComplementaryInputs(i, n)
%
% Inputs:
%    i                scalar index of the inputs (given by fnc_GetIndex)
%    n                number of total inputs
%
% Output:
%    cii               array of the corresponding complementary inputs
%
% ------------------------------------------------------------------------
% See also 
%          fnc_GetIndex         
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 30-01-2011
%
% History:
% 1.0  30-01-2011  First release.
%      23-09-2014  Changed: de2bi to bitget
%%
 
function cii = fnc_GetComplementaryInputs(i, n)

cii = find(bitget(2^n - i - 1, 1:(n+1)));
