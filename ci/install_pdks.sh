#!/bin/bash
#
# install_pdks.sh <pdk_root> --- Install the PDK versions listed in
# ../pdk_versions with "ciel", so that <pdk_root>/sky130A etc. exist.
# Used by the GitHub workflow; can also be run by hand to set up the same
# PDKs locally.

if [ $# -ne 1 ]; then
    echo "Usage: $0 <pdk_root>"
    exit 1
fi
PDK_ROOT=$1
VERSIONS=$(cd $(dirname $0)/.. && pwd)/pdk_versions

mkdir -p ${PDK_ROOT}
grep -v '^#' ${VERSIONS} | while read family version libraries; do
    [ -z "${family}" ] && continue
    libopts=""
    for lib in ${libraries}; do libopts="${libopts} -l ${lib}"; done
    echo "Installing ${family} ${version} (${libraries})"
    ciel enable --pdk-root ${PDK_ROOT} --pdk-family ${family} ${libopts} \
	${version} || exit 1
done
