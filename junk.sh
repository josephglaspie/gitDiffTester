#!/bin/bash

string="Some text with similarity index 100 in it."

if [[ $string == *"similarity index 100"* ]]; then
    echo "The string contains 'similarity index 100'."
else
    echo "The string does not contain 'similarity index 100'."
fi