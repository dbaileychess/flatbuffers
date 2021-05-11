#! /bin/bash

set -e

# To get the fully qualified name of the git repo
GIT_REPO_BASE=`git rev-parse --show-toplevel`

# Generate doc location
OUTPUT_DIR=$GIT_REPO_BASE/docs

# Flatbuffer's Documenation source
DOC_SRC_BASE=$GIT_REPO_BASE/docs_src

# A place to download and store the slate repo, without having it checked in.
SLATE_TEMP_DIR=$DOC_SRC_BASE/.slate
SLATE_BASE=$SLATE_TEMP_DIR/slate
SLATE_SOURCE=$SLATE_BASE/source
SLATE_BUILD_DIR=$SLATE_TEMP_DIR/build

# Get Slate
echo "[INFO] Getting Slate"
mkdir -p $SLATE_TEMP_DIR
cd $SLATE_TEMP_DIR
if [ ! -d slate ]; then
  git clone https://github.com/dbaileychess/slate.git $SLATE_BASE
else
  echo "[INFO] Slate already present in $SLATE_BASE"
fi

# Set up Slate for build
echo "[INFO] Linking assets"
ln -fs $DOC_SRC_BASE/index.html.md \
    $SLATE_SOURCE/index.html.md
ln -fs $DOC_SRC_BASE/stylesheets/_variables.scss \
    $SLATE_SOURCE/stylesheets/_variables.scss
# Need to work on Logo
# ln -fs $DOC_SRC_BASE/images/fpl_logo_small.png \
#     $SLATE_SOURCE/images/logo.png
cd $SLATE_BASE
bundle install

# Execute build
echo "[INFO] Building documentation"
rm -rf $SLATE_BASE/docs
bundle exec middleman build --clean --build-dir=$SLATE_BUILD_DIR

mkdir -p $OUTPUT_DIR
rm -rf $OUTPUT_DIR
echo "[INFO] Moving build to $OUTPUT_DIR"
cp -R $SLATE_BUILD_DIR/. $OUTPUT_DIR

echo "[INFO] Done!"