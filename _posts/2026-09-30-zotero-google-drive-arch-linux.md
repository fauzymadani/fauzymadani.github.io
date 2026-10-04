---
title: "Automated Academic Reference Workflow: Zotero, Google Drive Sync & Database Backup on Arch Linux"
date: 2026-09-30 00:00:00 +0700
categories: [linux, workflow]
tags: [archlinux, zotero, rclone, systemd, bibtex]
---

Managing academic literature quickly becomes a mess when dealing with limited local storage, multi-device synchronization, and manual citation workflows. Default setups often force you to pay for extra Zotero storage or manually move PDF attachments around, creating unnecessary friction during writing sessions.
I wanted a frictionless, automated setup on Arch Linux that seamlessly handles my reading materials, reference database, and disaster recovery. The primary goals were to offload paper PDFs automatically to Google Drive without filling up local storage permanently, keep Zotero metadata synced freely as local linked attachments, continuously export an updated citation library for editors like Neovim or Emacs Org-mode, and automate lightweight database backups without relying on heavy cloud client bloat.
Here is how to set up an end-to-end automated academic workflow using Zotero, Rclone, Attanger, Better BibTeX, and systemd user services.

## 1. Prerequisites and Package Installation

Before setting up the automated mounts, backups, and plugins, install the necessary packages on Arch Linux using `pacman`. We need `rclone` for cloud interaction and `fuse3` to allow mounting cloud filesystems in user space.

```bash
sudo pacman -S rclone fuse3 aur/zotero-bin
```

Next, create the local directory mount point and the systemd user configuration directory if they do not already exist:

```bash
mkdir -p ~/GoogleDrive
mkdir -p ~/.config/systemd/user
```

## 2. Cloud Storage Mounting with Rclone

The foundation of this architecture relies on bidirectionally mounting Google Drive to a local directory using Rclone with FUSE caching. This ensures that the operating system treats the remote cloud directory as a standard local folder while keeping local disk usage minimal.

First, configure your remote by running `rclone config` in your terminal and following the interactive setup for Google Drive, naming the remote `gdrive`. Once authorized, automate its execution using a systemd user service so it mounts seamlessly on system boot without root privileges.

Create the service file at `~/.config/systemd/user/rclone-gdrive.service`:

```ini
[Unit]
Description=Rclone Google Drive Mount
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount gdrive:Zotero_PDFs %h/GoogleDrive \
  --vfs-cache-mode full \
  --vfs-cache-max-size 2G \
  --vfs-read-chunk-size 8M \
  --vfs-read-chunk-size-limit 64M \
  --dir-cache-time 24h \
  --attr-timeout 10m
ExecStop=/usr/bin/fusermount -u %h/GoogleDrive
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
```

Enable and start the background service using `systemctl --user enable --now rclone-gdrive.service`.

The key configuration parameters here are `--vfs-cache-mode full` combined with `--vfs-cache-max-size 2G`. This allows files to be cached locally for instant reading and background uploading, while strictly capping local cache size. The directory cache settings drastically reduce network overhead, making directory listings via terminal or file managers feel virtually instantaneous.

## 3. Attachment Automation via Zotero Attanger

Standard Zotero stores attachments internally inside `~/Zotero/storage`, which quickly exhausts Zotero's default cloud storage quota and duplicates local files. To bypass this, we use the Attanger plugin to intercept newly saved attachments and automatically convert them into linked files pointing to our mounted Google Drive folder.

Download the latest `.xpi` release from the Zotero Attanger GitHub repository. Inside Zotero, navigate to **Tools** > **Plugins**, click the gear icon, select **Install Plugin From File...**, and choose the downloaded file.

To configure Attanger, open Zotero Settings and navigate to the **Attanger** section. Set the **Attach file** option under *Attach Type* to **Link**. Under *Destination Path*, select `/home/yzuaf/GoogleDrive`. You can leave the *Subfolder* field blank or set `{{collection}}` if you want Attanger to mirror your Zotero collection hierarchy automatically in Google Drive.

## 4. Real-Time Citation Key Export with Better BibTeX

For writing papers in plain text editors or cloud platforms like Overleaf, manually updating BibTeX keys is error-prone. Better BibTeX (BBT) generates consistent citation keys and exports the bibliography in real time whenever changes occur.

After installing the Better BibTeX `.xpi` plugin, open **Edit** > **Settings** > **Better BibTeX**. Set the **Citation key formula** field to:

```text
auth.lower + year + shorttitle.lower
```

This constructs readable keys like `siau2020artificial` or `vaswani2017attention`. To finalize, right-click **My Library** in Zotero, select **Export Library...**, set the format to **Better BibTeX**, and enable **Keep updated** and **Background export**. Save the target file to `/home/yzuaf/GoogleDrive/references.bib`.

## 5. Automated Database Backup via Systemd User Timers

While PDFs are safely stored in Google Drive via `rclone mount`, your Zotero database (`zotero.sqlite`) contains all collections, tags, notes, and metadata. To guarantee zero data loss without slowing down performance or hitting API rate limits with hundreds of tiny plugin scripts (`translators/` and `styles/`), we set up an ultra-lightweight `systemd` user timer.

### Creating the Backup Service

Create `~/.config/systemd/user/zotero-backup.service`:

```ini
[Unit]
Description=Automated Zotero Database Backup via Rclone

[Service]
Type=oneshot
ExecStart=/usr/bin/rclone sync %h/Zotero gdrive:Zotero_Data_Backup \
  --exclude "storage/**" \
  --exclude "translators/**" \
  --exclude "styles/**" \
  --exclude "*.sqlite-wal" \
  --exclude "*.sqlite.tmp-wal" \
  --exclude "*.bak" \
  --delete-excluded
```

*Note: Excluding `translators/**` and `styles/**` keeps the upload minimal (~25 MB total, taking under 2 seconds), while `--delete-excluded` cleans up any unnecessary files on Google Drive.*

### Scheduling the Timer

Create `~/.config/systemd/user/zotero-backup.timer` to run every 2 days at 16:00:

```ini
[Unit]
Description=Run Zotero Backup Every 2 Days at 4 PM

[Timer]
OnCalendar=*-*-1/2 16:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

The `Persistent=true` directive ensures that if your system is powered off during the scheduled time, `systemd` will trigger the backup immediately upon boot.

Enable and activate the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now zotero-backup.timer
```

Verify the active timer schedule and execution status at any time:

```bash
systemctl --user list-timers zotero-backup.timer
journalctl --user -u zotero-backup.service
```

## Conclusion

With this environment fully established, capturing research materials becomes effortless. Clicking the Zotero Connector extension extracts metadata into Zotero while Attanger routes PDF attachments to your Rclone mount. Better BibTeX instantly updates your central `.bib` file, and an automated background `systemd` timer keeps your SQLite reference database safely backed up to Google Drive every two days with zero system overhead.
