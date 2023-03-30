#!/bin/bash

# Save the input file name
inputfile=$1

# Initiate a counter for the output files
counter=0
line_cnt=0
# Loop over each line in the input file

while read -r line; do
  
  # Check if line starts with ";"
  if [[ $line == \;* ]]; then
    # If yes, write all the lines until the next line that starts with ";"
    if [[ -n $tmp ]]; then
      # Check if the saved lines are only newline characters
      lines=($(echo "$tmp" | wc -l))
      if [[ $lines -eq 2 ]]; then
        :
      elif [[ $line_cnt > 0 ]]; then
        echo "[INFO] Writing to ./Debug/unsat_$counter.smt2..."
        printf '%s\n' "$tmp" > "./Debug/unsat_$counter.smt2"
      fi
    fi
  
    # Increase the counter
    counter=$((counter+1))
  
    # Unset the variable
    tmp=""
    
    # reset line counter
    line_cnt=0
  fi
  
  # Concatenate the non-empty lines to a variable
  if [[ $line == \;* ]]; then
    tmp="${tmp}${line}"$'\n'
  fi

  if [[ $line == \(* ]]; then
    line_cnt=$((line_cnt+1))
    tmp="${tmp}${line}"$'\n'
  fi

done < "$inputfile"

# Write the last section to a file
# printf %s "$tmp" > "./Debug/unsat_$counter.smt2"

# dir="./Debug"
# echo "[INFO] Deleting redundant files..."
# # Loop through each file in the directory
# for file in $(ls -1 $dir)
# do
#     # Check if the file is .smt2
#     if [[ ${file: -5} == ".smt2" ]]; then
#         # Read the file line by line and set flag to false
#         while read line
#         do
#             if [[ $line == \(* ]]; then
#                 flag=true
#             fi
#         done < $file

#         # Delete the file if flag is false
#         if [ "$flag" != true ]; then
#             rm "$dir/$file"
#         fi
#     fi
# done