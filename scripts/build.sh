#!/usr/bin/env bash
set -e

# ensure that from wherever we run the script from we start in the project root
# by getting the absolute path of the script and then going up one directory
PROJECT_ROOT=$(dirname $(realpath $0))/..
cd $PROJECT_ROOT

# get the target from the command line
TARGET=$1
if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target>"
    echo "Target can be: latex, typescript, vitest"
    exit 1
fi

# set the model directory, output directory, pdf directory, and html directory
MODEL_DIR=$PROJECT_ROOT/model
OUT_DIR=$PROJECT_ROOT/out
TARGET_DIR=$OUT_DIR/$TARGET
PDF_DIR=$OUT_DIR/pdf
HTML_DIR=$OUT_DIR/html

# remove the target directory and create it again
echo "Removing target directory..."
rm -rf $TARGET_DIR
echo "Creating target directory..."
mkdir -p $TARGET_DIR
echo "Target directory created."

# run the generator (pass version from env if set, e.g. in CI)
echo "Running generator..."
GEN_ARGS="--model-dir $MODEL_DIR --out $TARGET_DIR --target $TARGET"
if [ -n "${VERSION:-}" ]; then
    GEN_ARGS="$GEN_ARGS --version $VERSION"
fi
python3 -m ci.generators $GEN_ARGS


# if the target is latex, build the pdfs and html
if [ "$TARGET" == "latex" ]; then
    echo "Building PDFs and HTML..."
    cd $TARGET_DIR
    mkdir -p $PDF_DIR $HTML_DIR

    # for each latex file, build the pdf and html, ensure the build intermediate
    # files are cleaned up and the html and css files are copied to the $HTML_DIR
    for latex_file in *.tex; do
        echo "... processing $latex_file"
        # build the pdf and html sending the console output to /dev/null
        pdflatex -interaction=nonstopmode -halt-on-error $latex_file > /dev/null
        make4ht -c lyrebird-html.cfg $latex_file > /dev/null
        # get the latex_file name without exxtension
        latex_file_no_ext=$(basename $latex_file .tex)
        # remove the build intermediate files except for the log file
        rm -f $latex_file_no_ext.aux \
            $latex_file_no_ext.dvi \
            $latex_file_no_ext.out \
            $latex_file_no_ext.toc \
            $latex_file_no_ext.4ct \
            $latex_file_no_ext.4tc \
            $latex_file_no_ext.idv \
            $latex_file_no_ext.lg \
            $latex_file_no_ext.tmp \
            $latex_file_no_ext.xref
        # copy the pdf, html, and css files to the $PDF_DIR and $HTML_DIR
        mv $TARGET_DIR/$latex_file_no_ext.pdf $PDF_DIR
        mv $TARGET_DIR/$latex_file_no_ext.html $HTML_DIR
        mv $TARGET_DIR/$latex_file_no_ext.css $HTML_DIR
        # optionally move the png and svg files to the $HTML_DIR
        if [ -f "$TARGET_DIR/$latex_file_no_ext.png" ]; then
            mv $TARGET_DIR/$latex_file_no_ext.png $HTML_DIR
        fi
        if [ -f "$TARGET_DIR/$latex_file_no_ext.svg" ]; then
            mv $TARGET_DIR/$latex_file_no_ext.svg $HTML_DIR
        fi
    done
    echo "Done."
fi

# if the target is typescript, generate tests then build and run
if [ "$TARGET" == "typescript" ]; then
    echo "Generating tests from verification cases..."
    python3 -m ci.generators --model-dir $MODEL_DIR --out $TARGET_DIR --target vitest ${VERSION:+--version $VERSION}
    cd $TARGET_DIR
    echo "Installing dependencies..."
    npm install
    echo "Building code..."
    npm run build
    echo "Running tests..."
    npm run test
    echo "Starting server..."
    npm run start
    echo "Done."
fi