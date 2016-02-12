#!/bin/bash

################################################################################
# Copyright (c) 2016 George Macoukji (macoukji@gamesnet.org)
# License: CC-BY
# Licensed under a Creative Commons Attribution 4.0 International License.
# See here for more info: http://creativecommons.org/licenses/by/4.0/
################################################################################

###############################
# Script settings
# Update these for your environment
###############################

# This is the URL of the Bitcoin Classic binary distributable for your version of Linux.
CLASSIC_URL="https://github.com/bitcoinclassic/bitcoinclassic/releases/download/v0.11.2.cl1/bitcoin-0.11.2-linux64.tar.gz"

# This is the hash of the download archive, to verify it downloaded right.
# The authors of Classic will publish this in a file named SHA256SUMS.asc
# Copy the value for the file you selected here.
CLASSIC_HASH="3f4eb95a832c205d1fe3b3f4537df667f17f3a6be61416d11597feb666bde4ca"

# This is the temporary directory in your system.
# If you're not sure what that is, it's usually safe to leave this as the default.
TEMP_DIR="/tmp"


#####*****#####*****#####*****#####*****#####*****#####*****#####
#####*****#####*****#####*****#####*****#####*****#####*****#####
##                                                             ##
## Don't modify below here unless you know what you're doing.  ##
##                                                             ##
#####*****#####*****#####*****#####*****#####*****#####*****#####
#####*****#####*****#####*****#####*****#####*****#####*****#####


###############################
# Internal script settings
###############################

Temp_subdir="classic"


###############################
# Functions
###############################

#
# Downloads the archive for Bitcoin Classic and unzips it.
# Takes two parameters:
# 1: The URL of the archive to download
# 2: The path in which to download and unzip it.
#
DownloadClassic()
{
	typeset URL="$1"
	typeset Location="$2"

	# Store the old path we were in
	typeset OldPath="$PWD"

	# Get the filename of the Classic archive file
	Classic_filename="$(basename "$URL")"

	# Delete prior downloads
	cd "$Location"
	if [ -d "$Temp_subdir" ] ; then
		echo "Deleting prior download directory"
		rm -rf "$Temp_subdir"
	fi
	mkdir "$Temp_subdir"
	cd "$Temp_subdir"

	# Download Classic.
	echo "Downloading Classic"
	wget "$URL"

	# Verify download is correct
	echo "Verifying download"
	typeset Download_Hash=$(sha256sum "$Classic_filename" | cut -f1 -d" ")
	if [ "$Download_Hash" != "$CLASSIC_HASH" ] ; then
		echo "ERROR: Could not download Bitcoin Classic correctly. Exiting." >&2
		echo "Downloaded file is: $Location/$Temp_subdir/$Classic_filename." >&2
		exit 2
	fi

	# Unzip Classic.
	echo "Unzipping Classic"
	tar -xvzf "$Classic_filename"

	# Return to the path we were in previously
	cd "$OldPath"
} # DownloadClassic()


###############################
# Check existing bitcoind
###############################

# Find the location of the bitcoin executables
Bitcoind_pathfile="$(which bitcoind)"

if [ -z "$Bitcoind_pathfile" ] ; then
	#bitcoind is not installed; just need to download.
	Version="not-installed"

	# The path we'll use to put the bitcoin executables is not known.
	# So, we'll take a good guess and stick them in the same directory as wget.
	Bin_Dir="$(dirname "$(which wget)")"
else
	# Figure out what version of bitcoin is installed now
	Version_String="$(bitcoind --version | head -1)"
	if echo "$Version_String" | grep -q "Bitcoin Core Daemon" ; then
		Version="Core"
	elif echo "$Version_String" | grep -q "Bitcoin XT Daemon" ; then # @TODO: Verify the XT version string
		Version="XT"
	elif echo "$Version_String" | grep -q "Bitcoin Classic Daemon" ; then
		Version="classic"
	else
		Version="other"
	fi

	# Get the directory name of the executables
	Bin_Dir="$(dirname "$Bitcoind_pathfile")"
fi

# Shut down bitcoind if it's running
echo "Stopping bitcoind."
bitcoin-cli stop 2>/dev/null
if [ 0 -eq $? ] ; then
	Bitcoind_was_started="true"
	# Give bitcoind a few seconds to exit while we do the download.
	sleep 5 &
else
	Bitcoind_was_started="false"
fi


###############################
# Download Bitcoin Classic
###############################

# Download and unzip Classic. Delete prior downloads
DownloadClassic "$CLASSIC_URL" "$TEMP_DIR"

# Figure out what the unzipped directory name is
UnzipDir="$TEMP_DIR/$Temp_subdir/$(cd "$TEMP_DIR/$Temp_subdir/"; ls -l | grep ^d | awk '{print $NF}')"


###############################
# Prepare for installation
###############################

# Wait for bitcoind to exit
echo "Waiting for bitcoind to exit"
wait

# Set up the sudoscript
echo "#!/bin/bash" > "$TEMP_DIR/$Temp_subdir/sudoscript.sh"

# Check if the old executables are actual files or symbolic links (such as from running this script before).
File_type=$(ls -l "$Bitcoind_pathfile" | cut -c1)

# Rename or delete existing executables
if [ "not-installed" = "$Version" ] ; then
	# If no prior version of bitcoind is installed, then we don't need to clean up the old executables.
	# Run any old command so that bash doesn't complain about an empty if block.
	true
elif [ "l" = "$File_type" ] ; then
	# old executable is a symbolic link.  Just delete it.
	cat <<EOF >> "$TEMP_DIR/$Temp_subdir/sudoscript.sh"

		echo "Deleting old symbolic links"
		rm "$Bin_Dir/bitcoind"
		rm "$Bin_Dir/bitcoin-cli"
EOF

elif [ "classic" = "$Version" ] ; then
	# A previous version of classic is installed. Delete it.
	cat <<EOF >> "$TEMP_DIR/$Temp_subdir/sudoscript.sh"

		echo "Deleting prior Classic executables"
		rm "$Bin_Dir/bitcoind"
		rm "$Bin_Dir/bitcoin-cli"
EOF

else
	# Core, XT, or some other version is installed as an executable. Move them to that version.
	cat <<EOF >> "$TEMP_DIR/$Temp_subdir/sudoscript.sh"

		echo "Renaming old ($Version) executables"
		mv "$Bin_Dir/bitcoind" "$Bin_Dir/bitcoind-$Version"
		mv "$Bin_Dir/bitcoin-cli" "$Bin_Dir/bitcoin-cli-$Version"
EOF

fi

cat <<EOF >> "$TEMP_DIR/$Temp_subdir/sudoscript.sh"

	# Copy the Classic executables to the bin directory
	echo "Copying new Classic executables"
	cp "$UnzipDir/bin/bitcoin-cli" "$Bin_Dir/bitcoin-cli-classic"
	cp "$UnzipDir/bin/bitcoind" "$Bin_Dir/bitcoind-classic"

	# Create a soft (symbolic) link from the normal filenames to the classic executables.
	echo "Setting up Classic executables"
	cd "$Bin_Dir"
	ln -s bitcoin-cli-classic bitcoin-cli
	ln -s bitcoind-classic bitcoind

EOF


###############################
# Install Bitcoin Classic
###############################

echo
echo
echo "       ***** ***** ATTENTION ***** *****"
echo
echo "        Setting up Classic executables."
echo "You may be prompted for your password in a second."
echo "         Please enter it to continue."
echo
echo "       ***** ***** ATTENTION ***** *****"
echo
sleep 1

# Run the sudoscript
sudo sh "$TEMP_DIR/$Temp_subdir/sudoscript.sh"


###############################
# Clean up
###############################

# Restart bitcoind (as Classic) if it was started before the script
if [ "true" = "$Bitcoind_was_started" ] ; then
	echo "Starting bitcoind Classic"
	bitcoind
fi

# Clean up after ourselves
rm -rf "$TEMP_DIR/$Temp_subdir"

echo "All done!"
