%% GSA_FAST_GetSi: calculate the FAST sensitivity indices
% Ref: Cukier, R.I., C.M. Fortuin, K.E. Shuler, A.G. Petschek and J.H.
% Schaibly (1973). Study of the sensitivity of coupled reaction systems to uncertainties in rate coefficients. I Theory. Journal of Chemical Physics 
%
% Max number of input variables: 50
%
% Usage:
%   Si = GSA_FAST_GetSi(pro)
%
% Inputs:
%    pro                project structure
%
% Output:
%    Si                 vector of first order sensitivity coefficients
%
% ------------------------------------------------------------------------
% Citation: Cannavo' F., Sensitivity analysis for volcanic source modeling quality assessment and model selection, Computers & Geosciences, Vol. 44, July 2012, Pages 52-59, ISSN 0098-3004, http://dx.doi.org/10.1016/j.cageo.2012.03.008.
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
 

function Si = GSA_FAST_GetSi(pro)

% retrieve the number of input variables
k = length(pro.Inputs.pdfs);

% set the number of discrete intervals for numerical integration of (13)
% increasing this parameter makes more precise the numerical integration
M = 10;

% read the table of incommensurate frequencies for k variables
W = fnc_FAST_getFreqs(k);

% set the maximum integer frequency
Wmax = W(k);

% calculate the Nyquist frequency and multiply it for the number of
% intervals
N = 2*M*Wmax+1;

q = (N-1)/2;

% set the variable of integration
S = pi/2*(2*(1:N)-N-1)/N;
alpha = W'*S;

% calculate the new input variables, see (10)
NormedX = 0.5 + asin(sin(alpha'))/pi;

% retrieve the corresponding inputs for the new input variables. 
X = fnc_FAST_getInputs(pro, NormedX);

Y = nan(N,1);

% calculate the output of the model at input sample points
for j=1:N
    Y(j) = pro.Model.handle(X(j,:));
end

A = zeros(N,1);
B = zeros(N,1);
N0 = q+1;


% ----
f1  = sum( reshape(Y(2:end),2,(N-1)/2) ); 
fdiff = -diff( reshape(Y(2:end),2,(N-1)/2) );  

for j=1:N
    if mod(j,2)==0 % compute the real part of the Fourier coefficients
        sj = Y(1) ;
        for g=1:(N-1)/2
            sj = sj + f1(g)*cos(j*g*pi/N) ;
        end
        A(j) = sj/N ;
    else % compute the imaginary part of the Fourier coefficients
        sj = 0 ;
        for g=1:(N-1)/2
            sj = sj + fdiff(g)*sin(j*g*pi/N) ;
        end
        B(j) = sj/N ;
    end
end

% compute the total variance by summing the squares of the Fourier
% coefficients
V = 2*(A'*A + B'*B);

% calculate the sensitivity coefficients for each input variable
for i=1:k
     I = (1:M)*W(i) ;
     Si(i) = 2*(A(I)'*A(I) + B(I)'*B(I)) / V;
end
