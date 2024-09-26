#!/bin/bash

set -ex

# make an array of Brick versions
BRICK_VERSIONS="1.3 1.4 1.4.1 1.4.2"

# Create a temporary directory
#TEMP_DIR=$(mktemp -d)
rm -rf /tmp/rdf-toolkit
TEMP_DIR=/tmp/rdf-toolkit
CURRENT_DIR=$(pwd)
DEST=$CURRENT_DIR/site

mkdir -p $DEST

# Clone the repository and navigate into it
git clone https://github.com/KrishnanN27/rdf-toolkit "$TEMP_DIR"
cd "$TEMP_DIR"

cp $CURRENT_DIR/rdfconfig.json "$TEMP_DIR/explorer/"

# Install dependencies
npm ci

# Build NPM package
npm run build
npm install @rdf-toolkit/cli

# Copy ontologies to the appropriate directory
#mkdir -p "$TEMP_DIR/rdf-toolkit/explorer/vocab"
#cp -R $CURRENT_DIR/ontologies/ "$TEMP_DIR/rdf-toolkit/explorer/vocab"
#tree $TEMP_DIR/rdf-toolkit/explorer/vocab

# Copy config file
#cp $CURRENT_DIR/rdfconfig.json "$TEMP_DIR/rdf-toolkit/explorer/"

# download the latest version of Brick from github
wget -O $CURRENT_DIR/ontologies/brick/latest/Brick.ttl https://github.com/BrickSchema/Brick/releases/download/nightly/Brick.ttl

# do the generic version-agnostic stuff first
cd "$TEMP_DIR/explorer"
npx rdf add file "https://brickschema.org/schema/Brick" $CURRENT_DIR/ontologies/brick/latest/Brick.ttl
npx rdf add file "http://qudt.org/2.1/schema/shacl/qudt" $CURRENT_DIR/ontologies/SCHEMA_QUDT_NoOWL-v2.1.ttl
npx rdf add file "http://qudt.org/2.1/vocab/unit" $CURRENT_DIR/ontologies/VOCAB_QUDT-UNITS-ALL-v2.1.ttl
npx rdf add file "http://qudt.org/2.1/vocab/quantitykind" $CURRENT_DIR/ontologies/VOCAB_QUDT-QUANTITY-KINDS-ALL-v2.1.ttl
npx rdf add file "http://www.w3.org/ns/shacl" $CURRENT_DIR/ontologies/shacl.ttl
npx rdf add file "https://brickschema.org/schema/Brick/ref" $CURRENT_DIR/ontologies/ref-schema.ttl
npx rdf add file "https://w3id.org/rec" $CURRENT_DIR/ontologies/rec.ttl
npx rdf make site --output "$DEST/$version" --project "$TEMP_DIR/explorer"

# loop through and build the site for each version by calling './b2.sh <version>'
for version in $BRICK_VERSIONS; do
  git checkout package.json
  # download the Brick version from https://brickschema.org/schema/$version/Brick.ttl
  # if the version is 'latest', then pull from https://github.com/BrickSchema/Brick/releases/download/nightly/Brick.ttl
  # put the result in vocab/brick/$version/Brick.ttl

  mkdir -p $CURRENT_DIR/ontologies/brick/$version
  wget -O $CURRENT_DIR/ontologies/brick/$version/Brick.ttl https://brickschema.org/schema/$version/Brick.ttl
  #./b2.sh $version
    cd "$TEMP_DIR/explorer"
    npx rdf add file "https://brickschema.org/schema/$version/Brick" $CURRENT_DIR/ontologies/brick/$version/Brick.ttl
    npx rdf make site --output "$DEST/$version" --project "$TEMP_DIR/explorer"
done

# Run add_versions.py on all .html files in the site directory
find "$DEST" -name "*.html" | xargs -n 1 -P 8 uv run "$CURRENT_DIR/add_versions.py"
