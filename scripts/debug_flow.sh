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

# Showing Metal Pitch Factor
printf '[INFO] Simplifying MP with the following Metal Pitch Factor ...
  ╔═══════ Metal Pitch Factor ══════╗
  ║ M1 MP Factor   = %6s         ║
  ║ M2 MP Factor   = %6s         ║
  ║ M3 MP Factor   = %6s         ║
  ║ M4 MP Factor   = %6s         ║
  ╚═════════════════════════════════╝\n' $M1_FACTOR $M2_FACTOR $M3_FACTOR $M4_FACTOR 

# Wait for user confirmation on input.
read -p "Continue (y/n)?" choice

case "$choice" in 
  y|Y ) echo "[INFO] Input confirmed. Running SMT CFET Design Flow ...";;
  n|N ) echo "[INFO] Exiting...";exit;;
  * ) echo "[ERROR] Invalid input. Exiting...";exit;;
esac

export workdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export workdir="${workdir%/*}"
export cfetdir="$workdir/CFET/PNR_4.5T_Extend"

# Step 1
echo "********** Generating Testcase **********"
echo "genTestCase_cfet.pl [.cdl file] [$offset]"
# offset
a=$(($M1_FACTOR))
b=$(($M2_FACTOR))
offset=$(( a > b ? a : b ))
offset=$(($offset+3))
$cfetdir/scripts/genTestCase_cfet_v3.0.pl ./Library/ASAP7_PDKandLIB_v1p5/asap7libs_24/cdl/lvs/asap7_75t_R.cdl $offset
cp -a ./pinLayouts_cfet_v3.0/. $cfetdir/pinLayouts_cfet 

# Step 2
echo "********** Generating SMT Input **********"
echo "genSMTInput_cfet.pl [.pinLayout file] [$BoundaryCondition] [$SON] [$DoublePowerRail] [$MAR_Parameter] [$EOL_Parameter] [$VR_Parameter] [$PRL_Parameter] [$SHR_Parameter] [$XOL_Parameter] [$MPL_Parameter] [$MM_Parameter] [$Local_Parameter] [$Partition_Parameter] [$BCP_Parameter] [$NDE_Parameter] [$BS_Parameter] [$PE_Parameter] [$M2_TRACK_Parameter] [$M2_Length_Parameter] [$Dint]\n\n"
testcase_dir=./pinLayouts_cfet_v3.0
pwd

for entry in "$testcase_dir"/*; do
  $cfetdir/scripts/genSMTInput_Ver3.01_cfet_debug.pl $entry
done

smt2_dir="$workdir/inputsSMT_cfet"

# check z3 MUS, split constraints, write to unsat.smt2 file
for entry in "$smt2_dir"/*; do
  # Do not look into unsat.smt2 as this is the output file
  if [[ $entry == $smt2_dir"/unsat.smt2" ]]; then
    continue
  fi
  echo "$entry"
  # write out z3 MUS
  z3 $entry > "$workdir/Debug/z3_log.txt"
  
  # split constraints
  ./Scripts/debug_split_smt.sh $entry

  # write out to unsat.smt2
  install -m 777 /dev/null $smt2_dir"/unsat.smt2"
  for _entry in ./Debug/*; do
    if [[ ${_entry: -5} == ".smt2" ]]; then
      echo "[INFO] Searching in Constraint ---> "$_entry
      ./Scripts/debug_unsat.sh ./Debug/z3_log.txt $_entry >> $smt2_dir"/unsat.smt2"
    fi
  done
done