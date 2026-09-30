---
title: "Automated Academic Reference Workflow: Zotero & Google Drive Sync on Arch Linux"
date: 2026-09-30 00:00:00 +0700
categories: [linux, workflow]
tags: [archlinux, zotero, rclone, systemd, bibtex]
---

Managing academic literature quickly becomes a mess when dealing with limited local storage, multi-device synchronization, and manual citation workflows. Default setups often force you to pay for extra Zotero storage or manually move PDF attachments around, creating unnecessary friction during writing sessions.
I wanted a frictionless, automated setup on Arch Linux that seamlessly handles my reading materials and reference database. The primary goals were to offload paper PDFs automatically to Google Drive without filling up local storage permanently, keep Zotero metadata synced freely while storing PDFs as local linked attachments, and continuously export an updated citation library for editors like Neovim, Emacs Org-mode, or Overleaf.
Here is how to set up an end-to-end automated academic workflow using Zotero, Rclone, Attanger, and Better BibTeX.

## 1. Prerequisites and Package Installation

Before setting up the automated mounts and plugins, install the necessary packages on Arch Linux using `pacman`. We need `rclone` for cloud interaction and `fuse3` to allow mounting cloud filesystems in user space.

```bash
sudo pacman -S rclone fuse3 aur/zotero-bin
```

Next, create the local directory mount point and the systemd user configuration folder if they do not already exist:

```bash
mkdir -p ~/GoogleDrive
mkdir -p ~/.config/systemd/user
```


## 2. Cloud Storage Mounting with Rclone

The foundation of this architecture relies on bidirectionally mounting Google Drive to a local directory using Rclone with FUSE caching. This ensures that the operating system treats the remote cloud directory as a standard local folder while keeping local disk usage minimal.

First, configure your remote by running `rclone config` in your terminal and following the interactive setup for Google Drive, naming the remote `gdrive`. Once the remote is authorized and working, we can automate its execution using a systemd user service so it mounts seamlessly on system boot without requiring root privileges.

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

The key configuration parameters here are `--vfs-cache-mode full` combined with `--vfs-cache-max-size 2G`. This allows files to be cached locally for instant reading and background uploading, while strictly capping local cache size to prevent cluttering your drive. The directory cache settings `--dir-cache-time 24h` and `--attr-timeout 10m` drastically reduce network overhead, making directory listings via terminal or file managers feel virtually instantaneous.


## 3. Attachment Automation via Zotero Attanger

Standard Zotero stores attachments internally inside `~/.zotero/`, which quickly exhausts Zotero's default cloud storage quota and duplicates local files. To bypass this, we use the Attanger plugin to intercept newly saved attachments and automatically convert them into linked files pointing to our mounted Google Drive folder.

Download the latest `.xpi` release from the Zotero Attanger GitHub repository. Inside Zotero, navigate to **Tools** > **Plugins**, click the gear icon in the top right, select **Install Plugin From File...**, and choose the downloaded file. Restart Zotero to finish the installation.

To configure Attanger, open Zotero Settings and navigate to the **Attanger** section on the sidebar. Set the **Attach file** option under *Attach Type* to **Link**. Under the *Destination Path* section, click **Choose...** and select `/home/yzuaf/GoogleDrive`. You can leave the *Subfolder* field blank if you prefer a flat storage layout, or keep `{{collection}}` if you want Attanger to mirror your Zotero collection hierarchy automatically in Google Drive.


## 4. Real-Time Citation Key Export with Better BibTeX

For those writing papers in plain text editors or cloud platforms like Overleaf, manually updating BibTeX keys is error-prone. Better BibTeX (BBT) solves this by generating consistent citation keys and exporting the bibliography in real time whenever changes occur in Zotero.

After installing the Better BibTeX `.xpi` plugin using the same plugin manager interface, open **Edit** > **Settings** > **Better BibTeX**. In modern BBT versions, citation key formulas use an updated syntax without brackets. Set the **Citation key formula** field to:

```text
auth.lower + year + shorttitle.lower
```

This expression constructs readable and collision-resistant citekeys like `siau2020artificial` or `vaswani2017attention`. The lowercased text format integrates cleanly with auto-completion engines such as `telescope-bibtex` in Neovim or Org-cite in Emacs.

To finalize the pipeline, right-click **My Library** or any specific collection in Zotero and select **Export Library...**. Set the export format to **Better BibTeX**, and make sure to check **Keep updated** and **Background export**. Uncheck **Export Files** to prevent unnecessary file duplication since Attanger already manages PDF locations. Save the target file directly to `/home/yzuaf/GoogleDrive/references.bib`.


## Conclusion

With this environment fully established, capturing research materials becomes effortless. Clicking the Zotero Connector extension in your browser extracts metadata into Zotero while Attanger routes the PDF attachment to your Rclone mount directory. Rclone handles background syncing to Google Drive without exhausting disk space, and Better BibTeX instantly updates your central `.bib` file for immediate use in your writing editor.
