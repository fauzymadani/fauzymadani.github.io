---
title: Draw a Beautiful Diagram in Emacs
date: 2026-08-20 00:00:00 +0700
categories: [emacs]
tags: [emacs]
---

I've been using emacs for quite some time now, a decision I plan to stick with for now. Several years back I've been using Obsidian for note-taking, then I discovered Emacs Org Mode and its integration within the wider Emacs ecosystem.

Now I use Emacs for almost every purpose: note-taking, light coding, writing my blog, and more. It is simpler than Obsidian, with less distraction but more friction at the start.

Recently I installed Emacs `org-tree-slide` and `org-present` to present something in Emacs like a PowerPoint or Google Slides. I wondered if I could draw a diagram inside Emacs directly without using `artist-mode`, and discovered [uniline](https://github.com/tbanel/uniline), which lets you draw diagrams using Unicode.

## Installation

It is already available on [MELPA](https://melpa.org/#/uniline), so I can use `use-package` inside my `init.el`. I use the transient variant:

```emacs-lisp
(use-package uniline-transient
  :ensure uniline
  :after transient
  :commands (uniline-mode uniline-launch-interface)
  :config
  (global-set-key (kbd "C-<insert>") #'uniline-launch-interface))
```

After restarting Emacs and waiting for the package installation, run `M-x uniline-mode RET` and move the cursor with the arrow keys:

```text
                ╭──────────────────╮   ╭─╮      ╭╮ ╭─╮
  ╭─────────╮   │                  │   │░│╭╮╭╮  ││ │░│
  │ hello!  ├───┤   some text      ├───┤░├╯││╰╮╭╯╰─┤░│••→ hello from
  ╰─────────╯   │                  │   │░│ ││ ╰╯   │░│    uniline!
                ╰──────────────────╯   ╰─╯ ╰╯      ╰─╯
```

To quit uniline, press `C-c C-c` or run `M-x uniline-mode RET`. The interface is available through `M-x uniline-launch-interface RET` or `C-<insert>`.

```text
  ◆ ◊ ▪ ▫ △ → ╳ ▒ ░ ▓ ¤ ↔
```

## Notice

The 3D brushes are currently available only with the Hydra interface:

> 3D brushes are experimental. They are available only with the Hydra interface. Transient coming soon.

Use a font that supports Unicode, such as JetBrains Mono, Unifont, Agave, or FreeMono. I use JetBrains Mono because it is superior to me.

Check my [Emacs config](https://github.com/fauzymadani/.emacs.d) for more. This is my personal configuration and it will grow as my understanding evolves.

_"All editors can save your files, but only Emacs can save your souls!"_
