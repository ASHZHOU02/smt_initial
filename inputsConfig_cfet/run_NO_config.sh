#!/bin/bash
################################################################################
#Script Name	:run_noGR_config.sh                                                                                              
#Description	:Set Design Configuration in ENV VAR                                                                               
#Args           :                                                                                           
#Author       	:Yucheng Wang                                                
#Email         	:yuw132@ucsd.edu                                           
################################################################################
# set -e      # terminate after the first line that fails

: '
##### MODE #####################################################################
=== BPRMode: Power Rail Location ===
# 0 => NONE
# 1 => METAL 1
# 2 => METAL 2
# 3 => Back-Power-Rail
=== MPOMode: Minimum Pin Openining: minimum I/O acess points ===
# 0 => NONE
# 1 => TWO
# 2 => THREE
# 3 => MAX
=== MH: Multi-height Design Enablement ===
# 0 => OFF
# 1 => ON, Double Track Height
=== TH: CFET Track Height ===
# [2.5T, 4.5T, 6T] => Track Height
################################################################################
'
export BPRMode=3            # Not used
export MPOMode=2
export MH=1                 # TODO
export TH=4                 # TODO

: '
##### Technology Parameters ####################################################
=== CPPWidth: Contact Poly Pitch ===
################################################################################
'
# Contact Poly Pitch Width
export Tungsten=1
# Vertical Layer (User defined MP & offset)
export M1_MP=50
export M1_OFFSET=0
export M3_MP=30
export M3_OFFSET=0
# Horizontal Layer (User defined MP, Pre defined offset)
export M2_MP=22
export M2_OFFSET=0              # compute from Metal pitch
export M4_MP=22
export M4_OFFSET=0

# Compute MP factors, accounting OFFSET as well
export M1_FACTOR=0
export M2_FACTOR=0
export M3_FACTOR=0
export M4_FACTOR=0

# GCF should be greater than 1 if two factors are not 1
GCF() (
    if (( $1 % $2 == 0)); then
        echo $2
    else
        GCF $2 $(( $1 % $2 ))
    fi
)

# Prechecking if MPs has greatest common factors > 1
precheck_MP() (
    # if both are 1, no need to check
    if [ $1 == 1 ] || [ $2 == 1 ]; then
        local factor_1=$1
        local factor_2=$2
        echo "$factor_1 $factor_2"
        echo "├──> Pitch checking passed." >&2
        return 1
    fi

    local factor=$(GCF "$1" "$2")
    
    if [ "$(($factor))" -le 1 ]; then
        echo "├──> Pitch checking failed. Common factor needs to be greater than 1." >&2
        echo "└──>Exiting......" >&2
        exit 1
    fi

    local factor_1=$(($1 / $factor))
    local factor_2=$(($2 / $factor))
    echo "$factor_1 $factor_2"
    echo "├──> Pitch checking passed." >&2
)

# Prechecking if Vertical Offsets are identical
precheck_OFFSET() (
    # if both are 1, no need to check
    if [ $1 == $2 ]; then
        echo "└──> Offset checking passed." >&2
        return 1
    fi

    echo "├──> Offset checking failed." >&2
    echo "└──>Exiting......" >&2
    exit 1
)

# Prechecking Vertical Layer
echo "[INFO] Prechecking Vertical Layer MP..."
read M1_FACTOR M3_FACTOR < <(precheck_MP $M1_MP $M3_MP)
echo "└──> Vert. Layer MP factors: M1_FACTOR=$M1_FACTOR M3_FACTOR=$M3_FACTOR"
precheck_OFFSET $M1_OFFSET $M3_OFFSET

# Prechecking Horizontal Layer
echo "[INFO] Prechecking Horizontal Layer MP..." 
read M2_FACTOR M4_FACTOR < <(precheck_MP $M2_MP $M4_MP)
echo "└──> Hori. Layer MP factors: M2_FACTOR=$M2_FACTOR M4_FACTOR=$M4_FACTOR"
precheck_OFFSET $M2_OFFSET $M4_OFFSET

: '
##### Design Parameters ####################################################
=== genSMTInput parameter ===
################################################################################
'
# genSMTInput parameter
export BoundaryCondition=0;         # ARGV[1], 0: Fixed, 1: Extensible
export SON=1;                       # ARGV[2], 0: Disable, 1: Enable # [SON Mode] Super Outer Node Simplifying
export DoublePowerRail=0;           # ARGV[3], 0: Disable, 1: Enable
export MAR_Parameter=0;             # ARGV[4], 2: (Default), Integer
export EOL_Parameter=0;             # ARGV[5], 2: (Default), Integer
export VR_Parameter=0;              # ARGV[6], sqrt(2)=1.5 : (Default), Floating
export PRL_Parameter=0;             # ARGV[7], 1 : (Default). Integer
export SHR_Parameter=0;             # ARGV[8], 2 : (Default),  <2 -> No need to implement.
export MPL_Parameter=3;             # ARGV[9], 3: (Default) Other: Maximum Number of MetalLayer
export MM_Parameter=4;              # ARGV[10], 3: (Default) Other: Maximum Number of MetalLayer
export Local_Parameter=1;           # ARGV[11], 0: Disable(Default) 1: Localization for Internal node within same diffusion region
export Partition_Parameter=2;       # ARGV[12], 0: Disable(Default) 1: General Partitioning 2. Manual Partitioning
export BCP_Parameter=0;             # ARGV[13], 0: Disable 1: Enable BCP(Default)
export NDE_Parameter=0;             # ARGV[14], 0: Disable(Default) 1: Enable NDE
export BS_Parameter=0;              # ARGV[15], 0: Disable(Default) 1: Enable BS(Breaking Symmetry)
export PE_Parameter=0;	            # ARGV[16], 1: Pin Enhancement Function 2: Edge-based Pin Separation 3: Minimize PS=1 and PS=2
export M2_TRACK_Parameter=1;        # ARGV[17], 1: M2 track minimization
export M2_Length_Parameter=1;       # ARGV[18], 1; M2 Length minimization
export DINT=1                       # ARGV[19], 2; Default 1 M1 pitch
# export BoundaryCondition=0;         # ARGV[1], 0: Fixed, 1: Extensible
# export SON=1;                       # ARGV[2], 0: Disable, 1: Enable # [SON Mode] Super Outer Node Simplifying
# export DoublePowerRail=0;           # ARGV[3], 0: Disable, 1: Enable
# export MAR_Parameter=1;             # ARGV[4], 2: (Default), Integer
# export EOL_Parameter=1;             # ARGV[5], 2: (Default), Integer
# export VR_Parameter=1;              # ARGV[6], sqrt(2)=1.5 : (Default), Floating
# export PRL_Parameter=1;             # ARGV[7], 1 : (Default). Integer
# export SHR_Parameter=2;             # ARGV[8], 2 : (Default),  <2 -> No need to implement.
# export MPL_Parameter=3;             # ARGV[9], 3: (Default) Other: Maximum Number of MetalLayer
# export MM_Parameter=4;              # ARGV[10], 3: (Default) Other: Maximum Number of MetalLayer
# export Local_Parameter=1;           # ARGV[11], 0: Disable(Default) 1: Localization for Internal node within same diffusion region
# export Partition_Parameter=2;       # ARGV[12], 0: Disable(Default) 1: General Partitioning 2. Manual Partitioning
# export BCP_Parameter=1;             # ARGV[13], 0: Disable 1: Enable BCP(Default)
# export NDE_Parameter=0;             # ARGV[14], 0: Disable(Default) 1: Enable NDE
# export BS_Parameter=0;              # ARGV[15], 0: Disable(Default) 1: Enable BS(Breaking Symmetry)
# export PE_Parameter=1;	            # ARGV[16], 1: Pin Enhancement Function 2: Edge-based Pin Separation 3: Minimize PS=1 and PS=2
# export M2_TRACK_Parameter=1;        # ARGV[17], 1: M2 track minimization
# export M2_Length_Parameter=1;       # ARGV[18], 1; M2 Length minimization
# export DINT=2                       # ARGV[19], 2; Default 1 M1 pitch

