#!/bin/bash
export workdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export workdir="${workdir%/*}/CFET/PNR_4.5T_Extend"
#rm -rfv ./pinLayouts_cfet_v2.1 && mkdir pinLayouts_cfet_v2.1
rm -rfv ./pinLayouts_cfet_v3.0/*
rm -rfv ./inputsSMT_cfet/*
rm $workdir/list_cfet_all
rm -rfv $workdir/RUN_cfet/*
rm -rfv $workdir/pinLayouts_cfet/*
rm -rfv $workdir/solutionsSMT_cfet/*
rm ./ConvtoLef/*.txt
rm ./ConvtoLef/output/*.lef
rm ./ConvtoLef/output/Cell_Metrics.txt
