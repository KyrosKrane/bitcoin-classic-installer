# bitcoin-classic-installer
A script to download and install Bitcoin Classic binary clients in Linux.


---
### THIS REPOSITORY IS ARCHIVED AND IS NOT MAINTAINED.
### BITCOIN CLASSIC EFFECTIVELY NO LONGER EXISTS.
### DO NOT USE OR RUN THIS SCRIPT!
---


## How to use the script:
Well, obviously, you can download it directly from here. :) However, if you are running off a VPS or remote server, it can be a bit trickier. The easiest way is with wget:

```Bash
wget https://raw.githubusercontent.com/KyrosKrane/bitcoin-classic-installer/master/install_classic.sh
```

Now, open the script in your favorite text editor (I recommend nano, but you can use anything) and check the top three settings lines. Edit them if needed, then save and exit your editor. Lines starting with a # are comments, and are just for your reference.

```Bash
# This is the URL of the Bitcoin Classic binary distributable for your version of Linux.
CLASSIC_URL="https://github.com/bitcoinclassic/bitcoinclassic/releases/download/v0.11.2.cl1/bitcoin-0.11.2-linux64.tar.gz"

# This is the hash of the download archive, to verify it downloaded right.
# The authors of Classic will publish this in a file named SHA256SUMS.asc
# Copy the value for the file you selected here.
CLASSIC_HASH="3f4eb95a832c205d1fe3b3f4537df667f17f3a6be61416d11597feb666bde4ca"

# This is the temporary directory in your system.
# If you're not sure what that is, it's usually safe to leave this as the default.
TEMP_DIR="/tmp"
```

Finally, run the script like so:

```Bash
bash install_classic.sh
```

As always, please report any bugs or issues you find! The master repository for this script is:
https://github.com/KyrosKrane/bitcoin-classic-installer/

Donations gladly accepted: 1ETJxpvugKuEd8KtXUDcx2QxSbvHGTPBpf
