#!/bin/bash

# Licensed under GPLv3. See LICENSE for terms. (c) 2026 995qa.

winpart=""
efipart=""
wimfile=""
wimindex=""

main() {
  echo "This will apply Windows to a specified partition, then will install the Boot files into the EFI partition."
  if [ -z "$wimindex" ]; then
    wiminfo "$wimfile" | grep -E '^Index:|^Name:'
    read -p "Select the index: " wimindex
  fi
  wiminfo "$wimfile" $wimindex > /dev/null 2>&1
  if (( $? == 18 )); then
    echo "Specified index is invalid!"
    exit 2
  fi
  echo "Downloading BCD-SYS... (it's a surprise tool that will help us later)"
  wget https://github.com/jpz4085/BCD-SYS/releases/download/v2.3/bcd-sys-2.3-x86_64.AppImage
  chmod +x bcd-sys-2.3-x86_64.AppImage
  applywim
}

applywim() {
  wimapply "$wimfile" $wimindex "$winmnt"
  if (( $? != 0 )); then
    echo "wimapply failed! read the logs above to see what went wrong"
    clean
    exit 4
  fi
  efiapply
}

efiapply() {
  sudo -u "$SUDO_USER" ./bcd-sys-2.3-x86_64.AppImage -v "$winmnt"
  if (( $? != 0 )); then
    echo "wait whar"
    clean
    exit 5
  fi
  clean
}

clean() {
  if [[ $winmnt == /tmp/winmnt ]]; then
    echo "Unmounting Windows partition"
    umount /tmp/winmnt
    rmdir /tmp/winmnt
  fi
  if [[ $efimnt == /tmp/efimnt ]]; then
    echo "Unmounting EFI partition"
    umount /tmp/efimnt
    rmdir /tmp/efimnt
  fi
  rm bcd-sys-*
  exit
}

help() {
  echo "Usage: sudo ./wiminstall.bash -w [winpart] -e [efipart] -f [wimfile]"
  echo "-i [index]: Specifies the index (optional)"
}

while getopts "w:e:f:i:" opt; do
  case $opt in
    w) winpart="$OPTARG"  ;;
    e) efipart="$OPTARG"  ;;
    f) wimfile="$OPTARG"  ;;
    i) wimindex="$OPTARG" ;;
    ?) help
  esac
done

if [ -z "$winpart" ] || [ -z "$efipart" ] || [ -z "$wimfile" ]; then
  help
  exit
fi

if [ ! -f "$wimfile" ]; then
  echo "WIM image doesn't exist!"
  help
  exit 1
fi

winmnt=$(findmnt -n -o TARGET $winpart)
efimnt=$(findmnt -n -o TARGET $efipart)

if [ -z "$winmnt" ]; then
  mkdir /tmp/winmnt
  mount $winpart /tmp/winmnt
  if (( $? != 0 )); then
    echo "Cannot mount!"
    rmdir /tmp/winmnt
    exit 3
  fi
fi

if [ -z "$efimnt" ]; then
  mkdir /tmp/efimnt
  mount $efipart /tmp/efimnt
  if (( $? != 0 )); then
    echo "Cannot mount!"
    rmdir /tmp/efimnt
    exit 3
  fi
fi


if (( $EUID == 0 )); then
  if command -v wiminfo &> /dev/null; then
    main
  else
    echo "Make sure that wimlib-utils is installed!"
    exit
  fi
else
  echo "Run this as root."
  exit
fi
