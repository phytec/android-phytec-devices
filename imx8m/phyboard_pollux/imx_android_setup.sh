# This script is used to fetch the complete source for android build
# It will install android NXP release in WORKSPACE dir (current path by default)

echo "Start fetching the source for android build"

if [ "x$BASH_VERSION" = "x" ]; then
    echo "ERROR: script is designed to be sourced in a bash shell." >&2
    return 1
fi

# retrieve path of release package
REL_PACKAGE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "Setting REL_PACKAGE_DIR to $REL_PACKAGE_DIR"

if [ -z "$WORKSPACE" ];then
    WORKSPACE=$PWD
    echo "Setting WORKSPACE to $WORKSPACE"
fi

if [ -z "$android_builddir" ];then
    android_builddir=$WORKSPACE/android_build
    echo "Setting android_builddir to $android_builddir"
fi

mkdir -p "$android_builddir"
cd "$android_builddir"
repo init -u https://source.codeaurora.org/external/imx/imx-manifest.git -b imx-android-11 -m imx-android-11.0.0_1.2.1.xml --repo-branch=v2.4.1

rc=$?
if [ "$rc" != 0 ]; then
    echo "---------------------------------------------------"
    echo "-----Repo Init failure"
    echo "---------------------------------------------------"
    return 1
fi

retry=0
max_retry=3

repo sync
while [ $retry -lt $max_retry -a $? -ne 0 ]; do
    retry=$(($retry+1))
    echo "Try repo sync $retry time(s)"
    repo sync
done

      rc=$?
      if [ "$rc" != 0 ]; then
         echo "---------------------------------------------------"
         echo "------Repo sync failure"
         echo "---------------------------------------------------"
         return 1
      fi

# Copy all the proprietary packages to the android build folder

cp -r "$REL_PACKAGE_DIR"/vendor/nxp "$android_builddir"/vendor/
cp -r "$REL_PACKAGE_DIR"/EULA.txt "$android_builddir"
cp -r "$REL_PACKAGE_DIR"/SCR* "$android_builddir"

# Apply PHYTEC patches

git apply --unsafe-paths
--directory="$android_builddir"/vendor/nxp-opensource/imx-mkimage/
"$android_builddir"/device/nxp/imx8m/phyboard_pollux/patch/0001-Parsing-the-devicetree-name.patch

# unset variables

unset android_builddir
unset WORKSPACE
unset REL_PACKAGE_DIR

echo "Android source is ready for the build"
