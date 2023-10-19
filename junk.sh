#!/bin/bash

# Define a function that takes multiple parameters
function print_parameters() {
    echo "Parameters: $1 $2 $3"
}

# Call the function with multiple parameters
echo "this is it alone"
print_parameters "Apple" "Banana" "Cherry"

result=$(print_parameters "Apple" "Banana" "Cherry")
echo "this is it as a variable"
echo $result