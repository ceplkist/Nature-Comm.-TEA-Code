%% pdf_Normal: Normal Probability Density Function
%
% Usage:
%   x = pdf_Normal(N, mu, sigma)
%
% Inputs:
%     N                scalar, number of samples
%     mu               mean
%     sigma            standard deviation
%
% Output:
%     x                vector with the sampled data
%                      if N==0 -> x = [mu - 3*sigma, mu + 3*sigma]  
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

function x = pdf_Normal(N, mu, sigma)

if N==0
    x = [mu - 3*sigma, mu + 3*sigma];
else
    % sample a normal distribution function 
    x = normrnd(mu,sigma, [N 1]); 
end
    
