#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Error: Please provide the two branches to compare, eg, main and receiveFromCatalyst"
  echo "Usage: $0 <firstBranch> <secondBranch> [ >2 ==> keep temp files]"
  exit 1 # Exit with a non-zero status to indicate an error
fi

export out="prettyDiff.txt";
export referenceBranch=$1
export candidateBranch=$2
export nl='\n'


git diff $referenceBranch..$candidateBranch --ignore-space-change --ignore-space-at-eol                >  t01.txt
cat t01.txt | sed '/^index.*/d' >                                                                         t02.txt
cat t02.txt | sed "s/^--- a\//'-' == $referenceBranch: /; s/^[+][+][+] b\//'+' == $candidateBranch: /" >  t03.txt
cat t03.txt | sed "/^---/d; s/new file mode.*/(file does not exist in $referenceBranch)/" >               t04.txt
cat t04.txt | sed "/^---/d; s/deleted file mode.*/(file does not exist in $candidateBranch)/" >           t05.txt
cat t05.txt | sed "s/^[+][+][+]/'+' == /" >                                                               t06.txt
cat t06.txt | sed "/^Binary/s/and b\//and $candidateBranch/" >                                            t07.txt
cat t07.txt | sed "/^Binary/s/ files a\//files $referenceBranch/" >                                       t08.txt
cat t08.txt | sed "s/^diff ..git a\//${nl}Diffing /; s/ b\/.*//" >                                        t09.txt
cat t09.txt | sed "/.*No newline at end of file/d" >                                                      t10.txt
cat t10.txt  >                                                                                            $out

egrep "Diffing|does not exist" $out | grep -v "^+" | sed "s/\(.*does not exist.*\)/\1${nl}/"
if [ "$#" -lt 3 ]; then
  rm -rf t??.txt
fi

#git diff $referenceBranch..$candidateBranch --name-only --ignore-space-change --ignore-space-at-eol > diffs-name.txt
#for i in `cat diffs-name.txt`
# do
#   export shortName=`echo $i | sed 's/Website.*StaticFiles.//'`
#   echo "git diff $referenceBranch..$candidateBranch -- $shortName --w --ignore-blank-lines \
#     | sed '/^index/d' | sed '/^[+][+][+]/d'"
# done
# rm -f diffs-name.txt
