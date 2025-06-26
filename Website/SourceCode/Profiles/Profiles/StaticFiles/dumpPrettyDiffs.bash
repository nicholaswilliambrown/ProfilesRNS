#!/bin/bash

export out="pretty-diffs.txt";
export candidateBranch="receiveFromCatalyst"
rm -rf $out

git diff master..$candidateBranch --name-only --ignore-space-change --ignore-space-at-eol > diffs-name.txt
for i in `cat diffs-name.txt`
 do
   export shortName=`echo $i | sed 's/Website.*StaticFiles.//'`
   echo "@========== $shortName =========================================" >> $out
   echo  " '-' == master. '+' = fromCatalyst"                              >> $out
   echo                                                                    >> $out
   # https://git-scm.com/docs/diff-options
   git diff master..$candidateBranch -- $shortName --w --ignore-blank-lines \
     | sed '/^index/d' | sed '/^[+][+][+]/d' | sed '/^---/d' | \
     sed '/diff --git a/d'                                                 >> $out
   echo                                                                    >> $out
 done

 rm -f diffs-name.txt
