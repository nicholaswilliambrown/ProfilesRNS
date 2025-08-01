


if [ "$#" -ne 1 ]; then
  echo "Error: Name of folder is required."
  echo "Usage: $0 <folder>"
  exit 1 # Exit with a non-zero status to indicate an error
fi

export folder=$1

if [[ -z "$folder" ]]; then
    echo "Usage: checkFolder <folder-to-compare-against>" 1>&2
    echo "E.g.: checkFolder OpenSource" 1>&2
    exit 1
fi

echo "Comparing with folder: <$folder>"

for i in css js json
  do echo "Diffing myBranding.$i with folder: <$folder>"
    diff myBranding.$i $folder
done
