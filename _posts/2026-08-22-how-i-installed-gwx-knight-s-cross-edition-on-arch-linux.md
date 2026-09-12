---
title: How I Installed GWX Knight's Cross Edition on Arch Linux
date: 2026-08-22 00:00:00 +0700
categories: [linux, games]
tags: [modding, games, linux]
---

I love war games, especially those about World War 2 with historical weapons or machinery. I am fond of submarine simulator games with good mechanics and do not care much about graphics.

I managed to run the game with Steam using Proton. Later I discovered the megamod for Silent Hunter 3 called [GWX - Knight's Cross Edition](https://thegreywolves.com/), a successor to the Grey Wolves eXpansion.

I researched how to install it, joined their Discord server, and found someone explaining the process. I started by preparing all the necessary resources.

## Installing Necessary Resources

Install the launcher from the AUR:

```bash
$ yay -S --noconfirm faugus-launcher
```

After installing the launcher, download the megamod files from [MediaFire](https://www.mediafire.com/file/ls3rxmqyky9wuv2/GWX-Knights_Cross_Edition_v2.5.7z/file) and install 7zip.

Remember to run the original Silent Hunter 3 from Steam once before doing anything else.

## Putting It Together

Create a main entry in the launcher:

1. Open the launcher and create a new entry.
2. Fill in any title.
3. Enter the path: `/home/user/Games/GWX-KnightsCross/sh3.exe`.
4. Use the Steam prefix: `/home/user/Faugus/gwx---knights-cross-edition`.
5. Choose `GE-Proton-Latest`.

Create similar entries for `HsieOptionsSelector.exe` and `MultiSH3.exe`, using the same prefix and Proton version. Finally create an entry for `SH3 Commander/SH3Cmdr.exe`.

## Conclusion

Run SH3 Commander when you want to play and manage career entries. Buy the original game on Steam first, and keep this megamod in a separate directory rather than merging it with the Steam installation.
