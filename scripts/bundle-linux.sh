#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright (c) ibis inc.
# Additional terms under AGPL-3.0 section 7(b): see NOTICE.
# Build the desktop version for Linux as a folder and a tarball,
# target/release/ibisOffice-<version>-Linux.tar.gz.
#
#   scripts/bundle-linux.sh
#
# There is no automatic update on Linux (Linux builds are updated by hand), so
# no ibisOfficeUpdater is built or shipped. UI icons and fonts are embedded in
# the executable; the bundle adds the application icon (ibisOffice.png, from
# crates/ibis-office-app/macos/AppIcon.png), the desktop entry
# (ibisOffice.desktop), the third-party licences (Resources/Licenses) and the
# pictures of Word's art page borders (Resources/artborders, which the app
# reads from next to the executable).
#
# The tarball holds one folder:
#
#   ibisOffice-<version>-Linux/
#     ibisOffice                  the executable
#     ibisOffice.desktop          the desktop entry
#     ibisOffice.png              the application icon
#     Resources/
#       Licenses/license.md       the third-party components and their notices
#       Licenses/Carlito-OFL.txt  Carlito's licence (OFL-1.1 asks for it)
#       artborders/OfficeOpenXML-WordprocessingMLArtBorders.zip
#       artborders/ECMA-NOTICE.txt
set -euo pipefail
cd "$(dirname "$0")/.."

# The paths of this machine (the home folder, the repository) are not to go
# into the executable (Rust keeps source paths for panics and the like): they
# are rewritten to short relative ones, in a target directory of its own so
# that the everyday builds (target/release) are not rebuilt by the flags.
REMAP="--remap-path-prefix=$HOME/.cargo/registry/src=crates.io --remap-path-prefix=$HOME/.cargo/git/checkouts=git --remap-path-prefix=$HOME/.rustup=rustup --remap-path-prefix=$(pwd)=."
RUSTFLAGS="$REMAP" CARGO_TARGET_DIR=target/dist cargo build --release --locked -p ibis-office-app

# The version shown for Linux, from version.txt (a platform, a tab and its
# version, per line).
VERSION=$(awk -F'\t' '$1 == "Linux" { sub(/\r$/, "", $2); print $2 }' version.txt)
[[ -n $VERSION ]] || { echo "version.txt has no Linux line" >&2; exit 1; }

DIR=target/release/ibisOffice-$VERSION-Linux
rm -rf "$DIR"
mkdir -p "$DIR"
cp target/dist/release/ibisOffice "$DIR/ibisOffice"
cp crates/ibis-office-app/macos/AppIcon.png "$DIR/ibisOffice.png"

cat > "$DIR/ibisOffice.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ibisOffice
Comment=Office suite for Word, Excel and PowerPoint documents
Exec=ibisOffice %F
Icon=ibisOffice
Terminal=false
Categories=Office;WordProcessor;Spreadsheet;Presentation;
StartupWMClass=ibisOffice
MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.openxmlformats-officedocument.presentationml.presentation;application/vnd.ms-word.document.macroEnabled.12;application/vnd.ms-excel.sheet.macroEnabled.12;application/vnd.ms-powerpoint.presentation.macroEnabled.12;
EOF

# The third-party components in the executable and the notices their licences
# ask for (made afresh from the dependencies), and Carlito's licence on its own
# (OFL-1.1 asks for it with the font).
python3 scripts/gen-web-licenses.py linux
mkdir -p "$DIR/Resources/Licenses"
cp crates/ibis-office-app/linux/license.md "$DIR/Resources/Licenses/license.md"
cp crates/ibis-office-app/fonts/carlito/OFL.txt "$DIR/Resources/Licenses/Carlito-OFL.txt"
# The pictures of Word's art page borders: ECMA-376's zip, unmodified, with
# its notice (read when a document uses an art border; not in the executable).
# The app looks for Resources/artborders next to the executable, so the layout
# is exactly this.
mkdir -p "$DIR/Resources/artborders"
cp crates/ibis-office-app/data/artborders/OfficeOpenXML-WordprocessingMLArtBorders.zip crates/ibis-office-app/data/artborders/ECMA-NOTICE.txt "$DIR/Resources/artborders/"

TARBALL=target/release/ibisOffice-$VERSION-Linux.tar.gz
tar -C target/release -czf "$TARBALL" "ibisOffice-$VERSION-Linux"

echo "Built $TARBALL. Unpack it anywhere and run ./ibisOffice, or copy ibisOffice.desktop to ~/.local/share/applications/ and set Exec and Icon to absolute paths."
