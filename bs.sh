#!/bin/bash

# Check if Git working tree is dirty
echo "Check if Git working tree is dirty"
if [[ $(git diff --stat) != "" ]]; then
  echo "dirty";
else
  echo "clean";
fi;
