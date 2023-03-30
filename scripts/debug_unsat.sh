#!/bin/bash

FILE=$1
SMT2=$2

FIRST=$(head -n 1 $FILE)
if [ $FIRST == "sat" ]; then
  exit 0
elif [ $FIRST == "unsat" ]; then
  SECOND=$(head -n 2 $FILE | tail -n 1)
  #Create an array containing all strings starting with c
  title="`grep ";" $SMT2`"
  array=($(echo $SECOND | grep -o "\bc[^ ]*\b"))
  #Loop through the array and use each string as input for grep in another file

  ifFOUND=0
  for string in "${array[@]}"
  do
  if OUTPUT=$(pfiles "$1" 2> /dev/null | grep ":named $string))" $SMT2)
  then
    if [[ $ifFOUND -eq 0 ]]; then
      echo $title
    fi
    echo $OUTPUT
    ifFOUND=$((ifFOUND+1))
  fi
  done
fi