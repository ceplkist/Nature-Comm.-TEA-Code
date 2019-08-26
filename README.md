
Automatic Process Synthesis Framework 
============

Matlab code for an effective automatic process synthesis framework to guide process simulations, which are then employed to predict the levelized costs of chemicals (LCCs). In particular base code has been developed for technoeconomic analysis of electrochemical processes coupling the CO2 reduction reaction (CO2RR) with the organic oxidation reaction (OOR) promising techniques for producing clean chemicals and utilizing renewable energy. 

If you find a bug or have any question, you can either [create an issue](https://github.com/ceplkist/Nature-Comm.-TEA-Code/issues/new) or send an email. Repository is maintained by Jonggeol Na (black90star@gmail.com) and Ung Lee (ulee@kist.re.kr). 


#### Reference:
Jonggeol Na, Bora Seo, Jeongnam Kim, Chan Woo Lee, Hyunjoo Lee, Yun Jeong Hwang, Byoung Koun Min, Dong Ki Lee, Hyung-Suk Oh, & Ung Lee (2019). General Technoeconomic Analysis for Electrochemical Coproduction Coupling CO2
Reduction with Organic Oxidation. _Nature Communications_.[(link)](https://doi.org/)

If you are only interested in the algorithm, the algorithm contains the relevant part of the method that is published with the main paper.

Abstract:  
> Electrochemical processes coupling the CO2 reduction reaction (CO2RR) with the organic oxidation reaction (OOR) are promising techniques for producing clean chemicals and utilizing renewable energy. However, assessments of the economics of CO2RR–OOR technology remain questionable due to diverse CO2RR–OOR combinations and significant process design variability. Here, we report a technoeconomic analysis (TEA) of electrochemical CO2RR–OOR coproduction via conceptual process design and thereby propose potential economic combinations. We first develop a fully automated process synthesis framework to guide process simulations, which are then employed to predict the levelized costs of chemicals (LCCs). We then identify the global sensitivity of current density, Faraday efficiency (FE), and overpotential across 295 electrochemical coproduction processes to both understand and predict LCCs at various technology levels. The analysis highlights the promise that coupling CO2RR with value-added OOR can secure significant economic feasibility.



## Setup

### Obtaining

You can do one of the following to obtain the latest code package.

* **Download**:   zipped archive  [Nature-Comm.-TEA-Code-master.zip](https://github.com/ceplkist/Nature-Comm.-TEA-Code/archive/master.zip)
* **Clone**: clone the repository from github: ```git clone https://github.com/ceplkist/Nature-Comm.-TEA-Code.git```

### System Requirements

**Software Requirements:**
* **Matlab** To run the package, you need Matlab with the {Statistics and Machine Learning Toolbox and Parallel Computing Toolbox (option)}. Code was tested in Matlab versions R2018b-R2019a, on Window 10. We tried to use basic Matlab functionalities whenever possible, so that the code could be used in other versions of Matlab. Please feel free to let us know if you encounter any problem in other versions of Matlab.
* **Aspen Plus** To perform process synthesis and process simulation, you need Aspen Plus software from AspenTech. We used Aspen Plus V10 to conduct every process simulation for the paper.

**Hardware Requirements:**
The package requires only a standard computer, with enough RAM to support the handling of the data matrix and run Aspen Plus process simulator.


## Instructions for Use

We provide two example scripts to demonstrate how Multi-CD can be applied, with step-by-step tutorials.
Simply open a demo script in Matlab and run; preferably, run by sections to see the intermediate outcome of each step.
Example output plots from the demo scripts are included under [Data](Data).

All custom functions (that do the real job) are in the [Code](Code) folder.
If you find a function call in the demo and want to see a quick documentation of what it does, you can type 

```
help [function-name]
```

on the Matlab command line. For example, `help HS_calculation_all`. Note that `setpaths.m` should have been run in advance, if not already called in the beginning of the demo script.


### script1: Convergence check for CO2RR-OOR
Sequencial script of process synthesis, process simulation, technoeconomic analysis, and LCCs evaluation.
`script1_convergenceCheck.m` - demonstrates the Automatic Process Synthesis Framework for all CO2RR-OOR combinations at base case

`script1_convergenceCheckCascade.m` - demonstrates the Automatic Process Synthesis Framework for cascade CO2RR-OOR combinations at base case

`script1_convergenceCheckOptimal.m` - demonstrates the Automatic Process Synthesis Framework for all CO2RR-OOR combinations at optimal

`script1_convergenceCheckCascadeOptimal.m` - demonstrates the Automatic Process Synthesis Framework for cascade CO2RR-OOR combinations at optimal case


- If you are only interested a demo of how our Multi-CD algorithm works, you can skip this step and proceed directly to `demo2`. 
- Pre-processing is necessary if you want to start from a real Hi-C dataset. 
No Hi-C dataset is included in this package, but you can download one from a public database. 
See [Data/readme](Data/readme.md) for more information.

### script2: Global sensitivity analysis for CO2RR-OOR

`demo2_MultiCD.m` - demonstrates how Multi-CD works at a fixed lambda (which can be changed by user), by showing each step of the simulated annealing process.

- By default, this demo script runs with a simulated correlation matrix, generated by a multi-scale group model (see a separate [demo script](Code/gen_model/demo_gen_corrMat.m) for how it is generated). On a typical desktop computer, it takes only a few seconds to run this demo as provided. Feel free to try different values of `lambda`, to find domains at different scales.


### Application to real data

The demo scripts can be directly used to perform a Multi-CD analysis on real data.

- Prepare Hi-C data in a compatible `.mat` file format (see 
[Data/readme](Data/readme.md) for more information). Provide it as the input to `demo1`, and run to get a correlation matrix. Save the resulting correlation matrix to a file. This can be done by uncommenting the last lines in `demo1`. 
- The correlation matrix is now used as the input to `demo2`. To do this, change the data import option to `useRealData=true` in `demo2`, and make sure the file path/name is correctly specified.
- Options and parameters for the Multi-CD algorithm can be adjusted easily by changing the numbers in `demo2`. We tried to keep all parameter-setting explicit at the script level, so that the user does not need to look into the contents of the package.
- Run `demo2` repeatedly at different values of the Multi-CD scale parameter `lambda` (or modify the script to add a loop over `lambda`), to find the multi-scale domain solution.

The run time now depends on the size of your data, on your choice of temperature schedule, and/or how many different values of `lambda` you wish to try.




