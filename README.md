# targpg-mount

targpg-mount.sh uses cryptsetup to create a temporary disk image for safely extracting .tar.gpg files. This allows access to encrypted files other than text without directly writing them to disk and risking discovery through file recovery methods.

Usage: 
    ./targpg-mount.sh file.tar.gpg encrypted-image.img mount-point
