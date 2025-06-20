#!/bin/bash

export out="pretty-diffs.txt";
git diff master..fromCatalyst --name-only --ignore-space-change --ignore-space-at-eol > diffs-name.txt
for i in `cat diffs-name.txt`
 do
   export shortName=`echo $i | sed 's/Website.*StaticFiles.//'`
   echo "=======================================================================================" >> $out
   echo $shortName " '-' == master. '+' = fromCatalyst"                                           >> $out
   echo "=======================================================================================" >> $out
   echo                                                            >> $out
   git diff master..fromCatalyst -- $shortName \
     | sed '/^index/d' | sed '/^[+][+][+]/d' | sed '/^---/d' | \
     sed '/diff --git a/d'                                         >> $out
   echo                                                            >> $out
 done

 rm -f diffs-name.txt
