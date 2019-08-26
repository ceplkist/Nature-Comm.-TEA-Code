%% fnc_GetInputs: give the vector of the inputs corresponding to the index
%                (useful to scan all the possible combinations of the
%                inputs)
%              
% Usage:
%   ii = fnc_GetInputs(i)
%
% Inputs:
%    i                scalar index of the inputs (given by fnc_GetIndex)
%
% Output:
%    ii               array of the corresponding inputs
%
% ------------------------------------------------------------------------
% See also 
%          fnc_GetIndex         
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 29-01-2011
%
% History:
% 1.0  29-01-2011  First release.
%      23-09-2014  Changed: de2bi to bitget
%%

function ii = fnc_GetInputs(i)

ii = find(bitget(i, 1:(floor(log(i)/log(2)) + 1)));