%% pro_Create: Create an empty new project structure
%
% Usage:
%   pro = pro_Create()
%
% Inputs:
%
% Output:
%     pro                project structure
%                          .Inputs.pdfs: cell-array of the model inputs with the pdf handles
%                          .Inputs.Names: cell-array with the input names 
%                          .N: scalar, number of samples of crude Monte Carlo
%                          .Model.handle: handle to the model function
%                          .Model.Name: string name of the model
%                            
% ------------------------------------------------------------------------
% Citation: Cannavo' F., Sensitivity analysis for volcanic source modeling quality assessment and model selection, Computers & Geosciences, Vol. 44, July 2012, Pages 52-59, ISSN 0098-3004, http://dx.doi.org/10.1016/j.cageo.2012.03.008.
% See also 
%
% Author : Flavio Cannavo'
% e-mail: flavio(dot)cannavo(at)gmail(dot)com
% Release: 1.0
% Date   : 28-01-2011
%
% History:
% 1.0  28-01-2011  First release.
%%

function pro = pro_Create()

pro.Inputs.pdfs = {};
pro.Inputs.Names = {};
pro.N = 10000;
pro.Model.handle = [];
pro.Model.Name = [];
