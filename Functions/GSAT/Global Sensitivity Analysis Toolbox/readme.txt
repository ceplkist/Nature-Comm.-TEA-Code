
*** GSAT Global Sensitivity Analysis Tool ***

Basic steps to perform the Sensitivity Analysis by GSAT Toolbox. 

- Create a new project (pro_Create). 
- For each input variable of the model add an input with its distribution function to the project (pro_AddInput). This function requires to set the name of the variable and an handle to its probability density function (pdf) which allows the fnc_SampleInputs routine to know how to sample the input variables. Two pdfs are already implemented: the uniform in an interval and the Sobol’ one for the Sobol’ quasi-random distribution. 
- Initialize the computation (command GSA_Init). This step is needed to generate the two sets of random/quasi-random points useful for the Monte Carlo and quasi-Monte Carlo procedures. In particular, for generating the quasi-random sequence the code checks if the Matlab framework is furnished with the routine sobolset(Statistics Toolbox TM), otherwise an ad-hoc routine has been implemented to this purpose. The model is, then, evaluated on the points of the first set of data and the results are stored to be used in the sensitivity computation. - Calculate the sensitivity indices.

PS: To calculate only the first order global sensitivity coefficients it is more efficient to use GSA_FAST_GetSi than GSA_GetSy.

For research purposes and for any reference in the scripts, please refer to:
Cannavo' F., Sensitivity analysis for volcanic source modeling quality assessment and model selection, Computers & Geosciences, Vol. 44, July 2012, Pages 52-59, ISSN 0098-3004, http://dx.doi.org/10.1016/j.cageo.2012.03.008.


