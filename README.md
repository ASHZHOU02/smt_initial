# SMT-based Simultaneous Standard Cell Place-&-Route (SP&R)
This is an alpha release for our codebase on CFET technology with Gear Ratio enablement.
## Overview
This manual briefly summarizes the following flows to generate (i) SMT formulation file (.smt2 file) and (ii) solution files to review the cell layout result. With the given standard cell information inputs (.pinLayout file) which are extracted from the ASAP7 PDK library[1], our flow generates the SMT formulation. We provide a solution viewer to validate the transistor placement and in-cell routing result of the SMT formulation. We employ Z3 (Ver. 4.8.5) [[2]](https://github.com/Z3Prover/z3) as our SMT solver. Please find more details from our paper.
### Flow Chart for Our Proposed Framework
### File Content
## Installation on Linux, Mac

Our flow requires the following software/packages to work properly:
- Z3Prover
  ```bash
  # Linux
  sudo apt-get update
  sudo apt-get -y install z3
  # Mac
  brew install z3
  ```
- perl-JSON
  ```bash
  # download package
  wget https://src.fedoraproject.org/repo/pkgs/perl-JSON/JSON-2.53.tar.gz/7db1be00d44414c4962eeac222395a76/JSON-2.53.tar.gz
  tar xvfz JSON-2.53.tar.gz
  cd JSON-2.53
  perl Makefile.PL
  make
  make install
  ```
- GDSPy
  ```bash
  pip install gdspy
  ```
## Quick Start
```bash
# set Design Parameters, Gear Ratio Info and more configurations as environmental variables
. ./inputsConfig_cfet/run_GR_config.sh
# run through the SMT design flow
./run_flow_gr.sh
```
## Our Tool-Chain Scripts and Commands with User-Specified Options
Our tool-chain scripts are written in Perl. SMT solver is Z3 (Ver. 4.8.5). For the information of the Z3 solver, please visit the following link: https://github.com/Z3Prover/z3
_Z3 Solver has been frequently updated. We recommend to use the specific version V4.8.5_
### Input Standard Cell Information (.pinlayout)
We provide 183 standard cell information which are extracted from the ASAP7 PDK library [1].
  ```bash
  $ ./scripts/genSMTInput_SPNR_Ver1.0.pl pinLayouts/AND2x2.pinLayout 1 1 1.5 1 1 3 2 1 0 5 1 1 1 1
  ```
###
### SMT Formulation Generation (genSMTinput_SPNR_Ver1.0.pl)
- Usage
  + All input parameters are accessed through environmental variables. These input settings are stored under `inputsConfig_cfet` directory. You may change the input based on your own design. We also provide documentation on details for each input.
  + **Cell Partitioning and Breaking Symmetry options can not be used at the same time.**
- Example
  + Generating the SMT formulation file (.smt2) for the AND2x2 standard cell “AND2x2.pinLayout” with the design rule parameters used in [3].
    ```bash
    $ ./scripts/genSMTInput_SPNR_Ver1.0.pl pinLayouts/AND2x2.pinLayout 1 1 1.5 1 1 3 2 1 0 5 1 1 1 1
    ```
  + This will create “AND2x2.smt2” file in the inputsSMT directory. For the .smt2 file format, please visit the following link: https://rise4fun.com/z3/tutorialcontent/guide
  + In our work [3], we set different parameters for combinational and sequential logic cells because we only applied the cell partitioning and crosstalk mitigation features to the sequential logic cells. Please refer to the pre-described command list (cmd_gen_smt) for the parameters applied to each cell in [3].
### RUN SMT Solver (z3)
- Usage
    ```bash
    # SMT Solving & Storing solution
    $ z3 inputsSMT/[inputFile(.smt2)] > RUN/[solutionName(.z3)]
    ```
- Example
    Running `AND2x2.smt2` file and storing the result `AND2x2.z3` to the output directory
    ```bash
    $ z3 inputsSMT/AND2x2.smt2 > RUN/AND2x2.z3
    ```
### Solution Converter (convSMTResult_Ver1.0.pl)
- Usage
    ```bash
    $ ./scripts/convILPResult_Ver1.0.pl [solPath/solutionName] [inputFile_pinLayout(w/o file extension)]
    ```
    Converting `AND2x2.z3` output file generated from the input pinLayout `AND2x2.pinLayout` to the
    solution output directory
    ```bash
    $ ./scripts/convSMTResult_Ver1.0.pl RUN/AND2x2.z3 AND2x2
    ```
- Example
    Converting `AND2x2.z3` output file generated from the input pinLayout `AND2x2.pinLayout` to the
    solution output directory
    ```bash
    $ ./scripts/convSMTResult_Ver1.0.pl RUN/AND2x2.z3 AND2x2
    ```
    This will create `[solutionName].conv` file in the solutionsSMT directory.
    The converted solution files (.conv) can be reviewed using an excel-based solution viewer. (SolutionViewer_3F_6T.xlsm)
### Pre-described Command Lists
There are `cmd_conv_solution`, `cmd_gen_smt` files which consist of command lists to generate and convert the whole standard cells provided in this package. You can refer to these command file to modify the parameters or execute each cell generation or sourcing the list file to execute all cases.
## Acknowledge
Our codebase is based on the work of Ho, Chia-Tung, who enabled the DTCO flow on CFET design in his published work _Machine Learning Prediction for Design and System Technology Co-Optimization Sensitivity Analysis_ [[4]](https://ieeexplore.ieee.org/document/9774927).
## Reference
[1] V. Vashishtha, M. Vangala, and L. T. Clark, “ASAP7 predictive design kit development and cell design technology co-optimization,” in 2017 IEEE/ACM International Conference on Computer-Aided Design (ICCAD), pp. 992–998, IEEE, 2017

[2] Z3, SMT Solver, https://github.com/Z3Prover/z3.

[3] D. Lee, D. Park, C.-T. Ho, I. Kang, H. Kim, S. Gao, B. Lin, C.-K. Cheng, “SP&R: SMT- based Simultaneous Place- &- Route for Standard Cell Synthesis of Advanced Nodes”, IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems, 2020

[4] C. -K. Cheng, C. -T. Ho, C. Holtz, D. Lee and B. Lin, "Machine Learning Prediction for Design and System Technology Co-Optimization Sensitivity Analysis," in IEEE Transactions on Very Large Scale Integration (VLSI) Systems, vol. 30, no. 8, pp. 1059-1072, Aug. 2022, doi: 10.1109/TVLSI.2022.3172938.