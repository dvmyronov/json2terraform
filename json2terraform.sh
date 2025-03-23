#jq and sed-based script for json to terraform convertion.
#Should be pretty fast

#!/bin/bash
name=$1
id=$2
json=$(cat)

#Firstly substitute the 1st line
echo "$json" | jq . | sed "1s/{/resource \"${name}\" \"${id}\" {/" | sed -n '
    s/^\([\t ]*\)"\(.*\":\)/\1\2/g;             #Removes the first " from keys
    s/":/ =/g;                                  #Substitube ": to = to convert JSON key-value pairs to Terraform syntax
    /{/ {/\\\\{/! {x;s/$/{/;x}};                #If { is found in pattern space; if not escaped by \\; swap hold space with pattern space and append {; then swap back
    /\[/ {/\\\\\[/! {x;s/$/\[/;x}};             #If [ is found in pattern space; if not escaped by \\; swap hold space with pattern space and append [; then swap back             
    /}/ {/\\\\}/! {x;s/.$//;x}};                #If } is found in pattern space; if not escaped by \\; swap hold space with pattern space; remove the last character, and swap back.
    /\]/ {/\\\\\]/! {x;s/.$//;x}};              #If ] is found in pattern space, if not escaped by \\; swap hold space with pattern space, remove the last character, and swap back.
    x;                                          #swap hold space and pattern space
    /{$/ {x;s/,$//;x};                          #if last char is {, swap back, remove trailing comma, and swap again. 
    x;                                          #swap hold space and pattern space
    /^.*= \".\{40\}/ {                          #If a value is at least 40 characters long, 
        s/\(^.*= \)"\(.*\)"/\1<<EOT\n\2\nEOT/g;     #convert it to a heredoc block (<<EOT ... EOT).
        s/\([${}\`"]\)/\\\1/g;                      #escapes ${}, backticks (`), and double quotes ("`).
    }
    p;                                          #print
'
