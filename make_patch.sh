#!/bin/bash
#
# ClamWin NSIS/VPatch updater
#
# Copyright (c) 2007-2012 Gianluigi Tiesi <sherpya@netfarm.it>
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

# ex: make_patch.sh 0.95.3 0.96 0.95.3.0 9600 0.96

genpatch="genpat.exe -O -B=32"

list_files()
{
	find . -type f \
	! -name "unins*" \
	! -name "*.conf" \
	| sed 's/\.\/\(.*\)/"\1"/' \
	| sort
}

if [ $# != 5 ]; then
  echo "Usage: $0 olddir newdir target_exe_version newversion_dw newversion_sz"
  exit 1
fi

archive=cwupdate.pat
manifest=cwupdate.lst
workmanifest=cwupdate.tmp
missing=cwupdate.mis
logfile=patch.log
olddir="$1"
newdir="$2"
target_exe_version="$3"
newversion_dw="$4"
newversion_sz="$5"

pushd "$newdir" >/dev/null 2>&1
list=$(list_files)
popd >/dev/null 2>&1

eval "filelist=($list)"
rm -f $archive
: > $manifest
echo "$target_exe_version" >> $manifest
echo "$newversion_dw" >> $manifest
echo "$newversion_sz" >> $manifest

: > $missing
echo $0 $* > $logfile

echo Starting incremental patch generation...
echo .

for f in ${filelist[*]}; do
	if [ ! -e "$olddir/$f" ]; then
		echo "Added: $f"
		echo $f >> $missing
	elif ! diff "$olddir/$f" "$newdir/$f" >/dev/null 2>&1; then
		echo "Patch: $f"
		$genpatch "$olddir/$f" "$newdir/$f" $archive >>$logfile 2>&1
		echo $f | sed 's/,.//'| tr / \\\\  >> $workmanifest
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
	echo Remember to add following files to missing subdir
	cat $missing
fi

rm -f $missing
