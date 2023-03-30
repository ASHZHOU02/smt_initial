#!/bin/bash
cat << EndOfMessage

   _____ __  __ _______    _____     _ _    _____                           _             
  / ____|  \/  |__   __|  / ____|   | | |  / ____|                         | |            
 | (___ | \  / |  | |    | |     ___| | | | |  __  ___ _ __   ___ _ __ __ _| |_ ___  _ __ 
  \___ \| |\/| |  | |    | |    / _ \ | | | | |_ |/ _ \ '_ \ / _ \ '__/ _\` | __/ _ \| \'__|
  ____) | |  | |  | |    | |___|  __/ | | | |__| |  __/ | | |  __/ | | (_| | || (_) | |   
 |_____/|_|  |_|  |_|     \_____\___|_|_|  \_____|\___|_| |_|\___|_|  \__,_|\__\___/|_|   
                                                                                          
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Version 3.0-Alpha Release

EndOfMessage
printf '[INFO] Reading Input Information from Environment Variables ...\n\n'

# Print User Configuration
printf '  ╔═════ Metal Pitch Parameter ═════╦═════ Metal Offset Parameter ════╗
  ║ M1 Metal Pitch = %6s         ║ M1 Metal Offset = %10s    ║
  ║ M2 Metal Pitch = %6s         ║ M2 Metal Offset = %10s    ║
  ║ M3 Metal Pitch = %6s         ║ M3 Metal Offset = %10s    ║
  ║ M4 Metal Pitch = %6s         ║ M4 Metal Offset = %10s    ║
  ╠══════════════════════ GenSMTInput Parameter ══════════════════════╣
  ║ BoundaryCondition   = %10s                                  ║
  ║ SON                 = %10s                                  ║
  ║ DoublePowerRail     = %10s                                  ║
  ║ MAR_Parameter       = %10s                                  ║
  ║ EOL_Parameter       = %10s                                  ║
  ║ VR_Parameter        = %10s                                  ║
  ║ PRL_Parameter       = %10s                                  ║
  ║ SHR_Parameter       = %10s                                  ║
  ║ MPL_Parameter       = %10s                                  ║
  ║ MM_Parameter        = %10s                                  ║
  ║ Local_Parameter     = %10s                                  ║
  ║ Partition_Parameter = %10s                                  ║
  ║ BCP_Parameter       = %10s                                  ║
  ║ NDE_Parameter       = %10s                                  ║
  ║ BS_Parameter        = %10s                                  ║
  ║ PE_Parameter        = %10s                                  ║
  ║ M2_TRACK_Parameter  = %10s                                  ║
  ║ M2_Length_Parameter = %10s                                  ║
  ║ DINT                = %10s                                  ║
  ╚═══════════════════════════════════════════════════════════════════╝
' $M1_MP $M1_OFFSET $M2_MP $M2_OFFSET \
$M3_MP $M3_OFFSET $M4_MP $M4_OFFSET \
$BoundaryCondition \
$SON \
$DoublePowerRail \
$MAR_Parameter \
$EOL_Parameter \
$VR_Parameter \
$PRL_Parameter \
$SHR_Parameter \
$MPL_Parameter \
$MM_Parameter \
$Local_Parameter \
$Partition_Parameter \
$BCP_Parameter \
$NDE_Parameter \
$BS_Parameter \
$PE_Parameter \
$M2_TRACK_Parameter \
$M2_Length_Parameter \
$DINT

# Wait for user confirmation on input.
read -p "Continue (y/n)?" choice

case "$choice" in 
  y|Y ) echo "[INFO] Input confirmed. Running SMT CFET Design Flow ...";;
  n|N ) echo "[INFO] Exiting...";exit;;
  * ) echo "[ERROR] Invalid input. Exiting...";exit;;
esac

export workdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export workdir="${workdir%/*}/CFET/PNR_4.5T_Extend"

# Step 1
echo "********** Generating Testcase **********"
echo "genTestCase_cfet.pl [.cdl file] [$offset]"
$workdir/scripts/genTestCase_cfet_v3.0.pl ./Library/ASAP7_PDKandLIB_v1p5/asap7libs_24/cdl/lvs/asap7_75t_R.cdl 1
cp -a ./pinLayouts_cfet_v3.0/. $workdir/pinLayouts_cfet 

# Step 2
echo "********** Generating SMT Input **********"
echo "genSMTInput_cfet.pl [.pinLayout file] [$BoundaryCondition] [$SON] [$DoublePowerRail] [$MAR_Parameter] [$EOL_Parameter] [$VR_Parameter] [$PRL_Parameter] [$SHR_Parameter] [$XOL_Parameter] [$MPL_Parameter] [$MM_Parameter] [$Local_Parameter] [$Partition_Parameter] [$BCP_Parameter] [$NDE_Parameter] [$BS_Parameter] [$PE_Parameter] [$M2_TRACK_Parameter] [$M2_Length_Parameter] [$Dint]\n\n"
testcase_dir=./pinLayouts_cfet_v3.0

# for entry in "$testcase_dir"/*; do
#   echo "$entry"
#   $workdir/scripts/genSMTInput_Ver3.01_cfet_debug.pl $entry
# done
for entry in "$testcase_dir"/*; do
  echo "$entry"
  $workdir/scripts/genSMTInput_Ver4.0_cfet.pl $entry ./config/config.json
  # $workdir/scripts/genSMTInput_Ver2.6_cfet.pl $entry 0 1 0 1 1 1 1 2 3 4 1 2 1 0 0 1 1 1 2
done

smt_dir=./inputsSMT_cfet

for entry in "$smt_dir"/*; do
  basename $entry .smt2 >> $workdir/list_cfet_all
done

# for entry in "$smt_dir"/*; do
#   basename $entry .smt2 >> $workdir/list_cfet_all_testing
# done

# Step 3
echo "********** Generating Z3 Solution **********"
echo "run_smt_cfet_forLef2.sh list_cfet_all"
cd $workdir
./run_smt_cfet_forLef3.sh list_cfet_all
cd -

# Step 4
echo "********** Generating LEF file **********"
echo "python generate.py [$metalPitch] [$cppWidth] [$siteName] [$mpoMode]"
cd ./ConvtoLef
python3 generate_cfet_v4.0.py 48 84 coreSite 2 "$workdir/solutionsSMT_cfet/" "./output"
