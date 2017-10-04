#!/bin/bash
echo "Content-type: text/html"
echo
TAG=`echo "$QUERY_STRING" | grep -o "id=[A-Z0-9]*" | cut -d = -f 2`
ECI="TT16NfLVjtLeBhoPo8NWb8"
NPE=`curl localhost:3001/sky/event/$ECI/none/tag/scanned?id=$TAG&tag_domain=enMotion`
MSG="Thank you for reporting a problem with this enMotion dispenser. Expect a repair by start of next business day."
cat <<EOF
<!doctype html>
<html>
<head>
<link rel="shortcut icon" href="/enMotion/favicon.ico">
<title>enMotion</title>
<meta charset="UTF-8">
</head>
<body>
<!-- 
<pre>$NPE</pre>
--> 
<p style="font-size:xx-large">$MSG</p>
</body>
</html>
EOF
