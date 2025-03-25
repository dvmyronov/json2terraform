#!/bin/bash

#Pure sed-based script to convert single string json to terraform format
json=$(cat)
name=$1
id=$2

echo "$json" | sed -E ' 
    s/^\{/\{\n/g;               #insert \n after first {
    s/([^\\])\{/\1\{\n/g;       #if { not preceded by escape \ insert \n after {
    s/([^\\])}/\1\n}/g;         #if } not preceded by escape \ insert \n before {

    s/\":\[/\":\[\n/g;

    s/([^\\])\],/\1\n\],/g;     #if ] not preceded by escape \ insert \n before ]
    s/,\"/,\n\"/g;              #if have ," insert \n between
    s/,\{/,\n\{/g;              #if have ,{ insert \n between
    
    :lb1; 
    s/}}/}\n}/g;                #if have }} insert \n between them
    tlb1;
    
    :lb2;
    s/]]/]\n]/g;                #if have ]] intsert \n between
    tlb2;
    
    s/}]/}\n]/g;                #if have ]} intsert \n between
    s/\[\{/\[\n\{/g;            #if have [{ insert \n between
' | sed -n '
    s/^\([\t ]*\)"\(.*\":\)/\1\2/g;             #Removes the first " from keys
    s/":/ = /g;                                 #Substitube ": to = to convert JSON key-value pairs to Terraform syntax
    /{/ {/\\\\{/! {x;s/$/{/;x}};                #If { is found in pattern space; if not escaped by \\; swap hold space with pattern space and append {; then swap back
    /\[$/ {/\\\\\[/! {x;s/$/\[/;x}};            #If [ is found in pattern space in the end of the line; if not escaped by \\; swap hold space with pattern space and append [; then swap back             
    /}/ {/\\\\}/! {x;s/.$//;x}};                #If } is found in pattern space; if not escaped by \\; swap hold space with pattern space; remove the last character, and swap back.
    /^[\t ]*\]/ {/\\\\\]/! {x;s/.$//;x}};       #If ] is found in pattern space in the beginning of the line, if not escaped by \\;  swap hold space with pattern space, remove the last character, and swap back.
    x;                                          #swap hold space and pattern space
    /{$/ {x;s/,$//;x};                          #if last char is {, swap back, remove trailing comma, and swap again. 
    x;                                          #swap hold space and pattern space
    /^.*= \".\{40\}/ {                          #If a value is at least 40 characters long, 
        s/\(^.*= \)"\(.*\)"/\1<<EOT\n\2\nEOT/g;     #convert it to a heredoc block (<<EOT ... EOT).
        s/\([${}\`"]\)/\\\1/g;                      #escapes ${}, backticks (`), and double quotes ("`).
    }
    p;                                          #print
' | sed "1s/{/resource \"${name}\" \"${id}\" {/"