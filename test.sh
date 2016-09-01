#!/usr/bin/env bash
wget -qO kicad-library-utils-master.zip https://github.com/KiCad/kicad-library-utils/archive/master.zip
unzip -qo kicad-library-utils-master.zip

PR_NUMBER=$(echo "$CI_PULL_REQUEST" | grep -Po '\/pull\/\K[0-9]+')

FILESTRING="$(curl -s https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$PR_NUMBER/files | jq -r '.[] .filename')"
read -ra FILES <<<$FILESTRING

for FILE in "${FILES[@]}"
do
  EXT="${FILE##*.}"
  if [ $EXT = "lib" ]; then
    echo "https://raw.githubusercontent.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/master/$FILE"
    wget -xq https://raw.githubusercontent.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/master/$FILE
    if [ $? -eq 0 ]; then
      # old file exists only check changed components
      COMPONENTSSTRING=$(python ./kicad-library-utils-master/schlib/comparelibs.py $FILE raw.githubusercontent.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/master/$FILE)
      read -ra COMPONENTS <<<$COMPONENTSSTRING
      for COMPONENT in "${COMPONENTS[@]}"
      do
        echo $COMPONENT
      done
    else
      echo "new file, check entire file $FILE"
      #check entire file
      python ./kicad-library-utils-master/schlib/checklib.py $FILE
    fi
  fi
done
