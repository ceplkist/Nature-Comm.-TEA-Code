
Automatic Process Synthesis Framework 
============

Matlab code for an effective automatic process synthesis framework to guide process simulations, which are then employed to predict the levelized costs of chemicals (LCCs). In particular, base code has been developed for technoeconomic analysis of electrochemical processes coupling the CO2 reduction reaction (CO2RR) with the organic oxidation reaction (OOR) promising techniques for producing clean chemicals and utilizing renewable energy. 

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

We provide example scripts to demonstrate how Automatic Process Synthesis Framework can be applied, with step-by-step tutorials.
Simply open a demo script in Matlab and run; preferably,

```
[script-name]
```

run by sections to see the intermediate outcome of each step. All custom functions (that do the real job) are in the [Functions](Functions) folder.

Note that `setpaths.m` should have been run in advance, if not already called in the beginning of the demo script.


### script1: Convergence check for CO2RR-OOR
Sequencial script of process synthesis, process simulation, technoeconomic analysis, and LCCs evaluation.

`script1_convergenceCheck.m` - demonstrates the Automatic Process Synthesis Framework for all CO2RR-OOR combinations at base case.

`script1_convergenceCheckCascade.m` - demonstrates the Automatic Process Synthesis Framework for cascade CO2RR-OOR combinations at base case.

`script1_convergenceCheckOptimal.m` - demonstrates the Automatic Process Synthesis Framework for all CO2RR-OOR combinations at optimal.

`script1_convergenceCheckCascadeOptimal.m` - demonstrates the Automatic Process Synthesis Framework for cascade CO2RR-OOR combinations at optimal case.

- Pre-processing is necessary if you want to start from a user-specific process systems dataset.
Our pre-processing contains `materials.mat` that involve overpotential, reaction information, phases, and other physicochemical properties of CO2RR and OOR reactions and `superstructure.mat` that involve pre-defined process superstructure of electrochemical CO2RR-OOR coproduction process.

### script2: Global sensitivity analysis for CO2RR-OOR

`script2_GlobalSensitivityAnalysis.m` - conducts global sensitivity analysis for CO2RR-OOR process under various current density, overpotential, and Faraday efficiency of each electrode.

`script2_GlobalSensitivityAnalysisCascade.m` - Cascade version.

- By default, this demo script runs with a parallel computing (CPUs) with 9 cores. If you want to run it using single core or different number of cores then please modify the code.

### script3-7: Post-processing

`script3_contourSampling.m` - LCC/market price contour graph with various current density and Faraday efficiency.

`script4_tsne.m` - performs t-Distributed Stochastic Neighbor Embedding (t-SNE) to reduce the dimensionality of process simulation results for visualization of design similarity.

`script5_heatmap.m` - LCC/market price heatmap for all combinations to identify the economics of CO2RR-OOR processes.

`script6_forReview_FDCA.m` - visualize LCC for various FDCA market price synerios for reviews.

`script7_forReview_CAPEX.m` - visualize local sensitivity of LCC/CAPEX ratio for various CAPEX cost (electrolyzer, distillation, extraction, flash, HX, PSA, ...) for reviews.

