#!/bin/bash

# Define a global variable
global_variable="This is a global variable"

# Function that uses the global variable
function print_global_variable() {
    echo "Global Variable is about to change: $global_variable"
    global_variable=foo
}

# Call the function
print_global_variable

# Access the global variable outside the function
echo "Accessing global variable outside function: $global_variable"
