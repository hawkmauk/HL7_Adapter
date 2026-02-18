#!/usr/bin/env bash
set -e

TOOLS=$HOME/sysml-tools
SYSML=$TOOLS/sysmlv2
PAPYRUS=$TOOLS/papyrus

MODEL_DIR=model
BUILD_DIR=build
OUT_DIR=dist/diagrams

mkdir -p $BUILD_DIR $OUT_DIR

echo "Parsing SysML v2 text..."
java -jar $SYSML/org.omg.sysml.cli.jar \
  parse $MODEL_DIR \
  -o $BUILD_DIR/model.xmi

echo "Validating model..."
java -jar $SYSML/org.omg.sysml.cli.jar \
  validate $BUILD_DIR/model.xmi

echo "Rendering diagrams..."
$PAPYRUS/papyrus \
  -nosplash \
  -application org.eclipse.papyrus.headless.commandline \
  -input $BUILD_DIR/model.xmi \
  -output $OUT_DIR \
  -format svg

echo "Done. Diagrams in $OUT_DIR"
