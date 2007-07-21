#!/bin/bash
#
# ClamWin NSIS/VPatch updater
#
# Copyright (c) 2007 Gianluigi Tiesi <sherpya@netfarm.it>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this software; if not, write to the
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

genpatch="genpat.exe -O -B=16"
#genpatch="genpat.exe"

list_files()
{
	find . -type f \
	! -name "unins*" \
	! -name "*.conf" \
	| sed 's/\.\/\(.*\)/"\1"/' \
	| sort
}

if [ $# != 5 ]; then
  echo "Usage: $0 olddir newdir oldversion version version_str"
  exit 1
fi

archive=cwupdate.pat
manifest=cwupdate.lst
workmanifest=cwupdate.tmp
missing=cwupdate.mis
olddir="$1"
newdir="$2"
oldver="$3"
version="$4"
versionstr="$5"

pushd "$newdir" >/dev/null 2>&1
list=$(list_files)
popd >/dev/null 2>&1

eval "filelist=($list)"
rm -f $archive
echo "$versionstr" > $manifest
echo "$oldver" >> $manifest
echo "$version" >> $manifest

: > $missing

echo Starting incremental patch generation...
echo .

for f in ${filelist[*]}; do
	if [ ! -e "$olddir/$f" ]; then
		echo "Added: $f"
		echo $f >> $missing
	elif ! diff "$olddir/$f" "$newdir/$f" >/dev/null 2>&1; then
		echo "Patch: $f"
		$genpatch "$olddir/$f" "$newdir/$f" $archive >/dev/null 2>&1
		echo $f | sed 's/,.//'| tr / \\  >> $workmanifest
	fi
done

sort $workmanifest | uniq >> ${manifest}
rm -f $workmanifest
dos2unix $manifest >/dev/null 2>&1

echo .
echo PatchFile: $archive
echo Manifest : $manifest

if [ -s $missing ]; then
	echo .
	echo Remeber to add following files to missing subdir
	cat $missing
fi

rm -f $missing
