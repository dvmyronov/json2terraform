The main idea is to use sed hold space as a kind of stack, where the top element indicate, should we delete trailing comma or not.
The flow is described below:
1. Preformat the json with jq . That's everything we need from jq.
2. Provide some simple conversions with sed:
- substitute the first line with Terraform resource type and id:  _sed "1s/{/resource \"${name}\" \"${id}\" {/"_
- removes the first " from keys:  _s/^\([\t ]*\)"\(.*\":\)/\1\2/g_
- substitube ": to = to convert JSON key-value pairs to Terraform syntax:  _s/":/ =/g_
3. For simple JSON structures this would be enough. But JSON could contain nested arrays, this arrays could contains objects, e.t.c. We need to know should we delete trailing comma. We should not delete trailing comma at an array level, because array elements in Terraform are separated by commas. So we use hold space to track this information.
4. How to track this:
- if { is found in pattern space, if { is not escaped by \\, swap hold space with pattern space and append {, then swap back: _/{/ {/\\\\{/! {x;s/$/{/;x}}_
- if [ is found in pattern space, if [ is not escaped by \\, swap hold space with pattern space and append [, then swap back: _/\[/ {/\\\\\[/! {x;s/$/\[/;x}}_
- If } is found in pattern space, if } is not escaped by \\, swap hold space with pattern space, remove the last character, and swap back: _/}/ {/\\\\}/! {x;s/.$//;x}}_
- If ] is found in pattern space, if ] is not escaped by \\, swap hold space with pattern space, remove the last character, and swap back: _/\]/ {/\\\\\]/! {x;s/.$//;x}}_
5. So the hold space will represent the current level of JSON processing. 
If the last char is {, that means object level, remove trailing comma.
If the last char is [, that means array level, do noting with trailing comma. (see code of the script)
6. The last conversions:
- convert long strings in heredoc format
- escape ${}\`" characters in text strings
7. And then we could print the result.

The script was tested with different JSON structures. The results were tested by _terraform fmt_ command. As an example, Cloudflare 5.1.0 terraform plugin JSON scheme that contains more than 78000 strings (after jq .) was converted for less than 1 second.
