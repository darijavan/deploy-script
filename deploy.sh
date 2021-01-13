#!/bin/bash
set -e

workingDirectory=${workingDirectory:-'./'}
branch=${branch:-main}
template=${template:-undefined}
outputDir=${outputDir:-undefined}

# Process entered named parameters
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

if [ $template = 'undefined' ];
then
  echo "You must specify the template to user: "
  echo
  echo "  deploy.sh --template [template_name]"
  echo
  echo "Options currently available:"
  echo "  - react"
  echo "  - symfony"
  exit 1
fi

# Change working directory
cd $workingDirectory

# Sync project with github
git fetch &> /dev/null
git checkout $branch
git pull &> /dev/null

if [ $template = 'symfony' ]; then
  if ! command -v composer &> /dev/null
  then
    echo "Composer not found. Composer is needed to run the script"
    exit 1
  fi

  echo "Installing composer dependencies..."
  echo

  composer install

  echo

  php bin/console doctrin:schema:update --force --env prod
  php bin/console assets:install --env prod
  php bin/console cache:clear --env prod

  echo "Add read/write permissions to var folder"
  chmod -R 755 ./var
elif [ $template = 'react' ];
then
  if [ $outputDir = 'undefined' ]; then
    echo "output directory not specified"
    exit 1
  fi

  if [ -d $outputDir ]; then
    mv $outputDir "$outputDir-backup"
  fi

  mkdir -p $outputDir

  npm install
  npm run build

  echo "Copying build files to outputDir"
  cp -r build/* "$outputDir"
fi