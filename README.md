The main idea is to use sed's hold space as a stack, where the top element indicates whether we should remove a trailing comma. The conversion process is as follows:

1. First, we format the JSON using jq .. This ensures a consistent structure and is the only preprocessing step required from jq.
2. Apply Basic Transformations with sed:
- Convert the first line into a Terraform resource declaration:  _sed "1s/{/resource \"${name}\" \"${id}\" {/"_
- Remove the leading quote from JSON keys:  _s/^\([\t ]*\)"\(.*\":\)/\1\2/g_
- Convert JSON key-value pairs to Terraform syntax (": → =):  _s/":/ =/g_
3. For simple JSON structures, these transformations are sufficient. However, nested arrays and objects require additional handling, particularly for trailing commas.
4. Since Terraform uses commas to separate array elements but not object properties, we need a way to determine whether to remove a trailing comma. We use sed's hold space to track the current JSON context:
- Entering an object ({) → Store { in hold space: _/{/ {x;s/$/{/;x}_
- Entering an array ([) → Store [ in hold space: _/\[/ {x;s/$/\[/;x}_
- Exiting an object (}) → Remove the last character from hold space: _/}/ {x;s/.$//;x}_
- Exiting an array (]) → Remove the last character from hold space: _/\]/ {x;s/.$//;x}_
5. So the hold space will represent the current level of JSON processing. 
- If the last character in hold space is {, we're at the object level and should remove trailing commas.
- If it's [, we're at the array level and should keep trailing commas.. (see code of the script)
6. Final Adjustments:
- Converting long strings to heredoc format.
- Escape ${}\`" characters in text strings
7. And then we could print the result.

The script was tested on various JSON structures and validated using terraform fmt. As an example, the Cloudflare 5.1.0 Terraform plugin JSON schema (over 78,000 lines after jq .) was successfully converted in under one second.
