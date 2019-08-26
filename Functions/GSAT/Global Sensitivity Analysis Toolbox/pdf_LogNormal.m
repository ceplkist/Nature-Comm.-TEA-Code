%% pdf_LogNormal: LogNormal Probability Density Function
%
% Usage:
%   x = pdf_LogNormal(N, m, s)
%
% Inputs:
%     N                scalar, number of samples
%     m                mean of the lognormal distribution 
%     s                standard deviation of the lognormal distribution
%
% Output:
%     x                vector with the sampled data
%                      if N==0 -> x = [m - 3*s, m + 3*s]
%                                   
%
% ------------------------------------------------------------------------
% See also 
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 28-12-2013
%
% History:
% 1.0  28-12-2013  First release.
%%

function x = pdf_LogNormal(N, m, s)


if N==0
    x = [m - 3*s, m + 3*s];
else
    mu = log((m^2)/sqrt(s^2+m^2));
    sigma = sqrt(log((s^2)/(m^2)+1));
    % sample a lognormal distribution function 
    x = lognrnd(mu,sigma, [N 1]); 
end
    
