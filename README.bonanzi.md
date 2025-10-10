# Bonanzi's Glove80 fork guide

This document collects everything specific to my `de-DE` QWERTY fork of
Sunaku's "Glorious Engrammer" layout. It explains the tooling you need on macOS,
which layers are preserved across upgrades, and the exact workflow for merging
new upstream releases while keeping my Symbol-layer Insert shortcuts and
World-layer `de-DE` scancodes intact.

> **TL;DR:** Keep `main` fast-forwarded from upstream, capture overrides before
> merging, regenerate `keymap.dtsi` with `rake dtsi`, then flash the rebuilt
> `.uf2` onto both halves and verify the Symbol/World layers still send the
> expected shortcuts and scancodes.

## Table of contents

- [1. Tooling prerequisites (macOS)](#1-tooling-prerequisites-macos)
- [2. Preserved layers overview](#2-preserved-layers-overview)
- [3. Capturing overrides](#3-capturing-overrides)
- [4. Detailed upgrade tutorial](#4-detailed-upgrade-tutorial)
  - [Understanding the branches I keep around](#understanding-the-branches-i-keep-around)
- [5. Troubleshooting tips](#5-troubleshooting-tips)
- [6. Reference files in this fork](#6-reference-files-in-this-fork)
- [7. Locale strategy and `de-DE` scancodes](#7-locale-strategy-and-de-de-scancodes)
  - [Locale selector vs. host keyboard layout](#locale-selector-vs-host-keyboard-layout)
  - [Maintaining the `de-DE` scancode translation](#maintaining-the-de-de-scancode-translation)
  - [Keeping custom layers across upgrades](#keeping-custom-layers-across-upgrades)

## 1. Tooling prerequisites (macOS)

1. Install Homebrew if you have not already: `https://brew.sh/`.
2. Install Ruby via Homebrew: `brew install ruby`.
3. Add Homebrew's Ruby to your shell `PATH` (zsh example):
   ```sh
   echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
4. Confirm the interpreters are available:
   ```sh
   ruby -v
   rake -V || gem install rake
   ```
5. (Optional) Install `rg` for fast searches: `brew install ripgrep`.

## 2. Preserved layers overview

The capture workflow keeps my customized versions of these layers:

- `QWERTY` (German base layer)
- `Symbol` (Insert-cluster copy/paste sends Ctrl+Insert and Shift+Insert)
- `World` (direct `de-DE` scancodes for umlauts and ß)

Both configuration files live under `custom/`:

- `custom/layers_to_preserve.json` lists the layer names to snapshot.
- `custom/layer-overrides.json` stores the captured key layouts.

Whenever I modify one of those layers in `keymap.json`, I must recapture the
snapshot before committing so the override file matches my latest edits.

## 3. Capturing overrides

Run the helper script from the repository root so the overrides stay current:

```sh
./scripts/capture_layer_overrides.rb
```

The script expects `keymap.json` and `custom/layers_to_preserve.json` to exist.
It writes an updated `custom/layer-overrides.json` and prints a warning if any
named layer could not be found. Commit both JSON files together.

<details>
<summary>Why capture overrides locally instead of the online editor?</summary>

The Glove80 configurator cannot express some of my bindings (e.g. the Symbol
layer's `LC(INS)`/`LS(INS)` copy-paste shortcuts), so those live only in
`custom/layer-overrides.json`. When the capture script runs it merges the
freshly exported layer with whatever is already in the overrides file,
preserving any hand-edited entries that do not exist in `keymap.json`.

</details>

## 4. Detailed upgrade tutorial

Follow these steps whenever Sunaku publishes a new release that I want to adopt.
This workflow keeps my branch in sync with upstream via merges while
fast-forward updates remain possible.

### Understanding the branches I keep around

I use three long-lived branches/remotes and treat them as dedicated roles in the
workflow above:

- **`upstream/main`** – the source of truth for Sunaku's project. I never commit
  directly onto this remote-tracking branch; instead I `git fetch upstream`
  before every upgrade so my local `main` can fast-forward to it.
- **`main`** – my local mirror of upstream. After fetching, I check out `main`
  and fast-forward it (`git pull --ff-only upstream main`). This branch contains
  no personal commits; it simply stays aligned with upstream so merges are
  clean. When I want my fork on GitHub to match, I push the fast-forwarded
  branch back to `origin main`.
- **`bonanzi-de`** (or whichever customization branch I'm using) – the branch
  that holds my actual layout changes. All commits I author land here. Merging
  the refreshed `main` into this branch keeps my history current while
  preserving my custom layers.

Thinking about the branches this way keeps responsibilities clear: upstream is
where releases come from, `main` is my pristine tracking copy, and
`bonanzi-de` is the working branch that layers my personal tweaks on top.


1. **Sync remotes**

   ```sh
   git fetch origin
   git fetch upstream
   ```

   <details>
   <summary>Tips</summary>

   Replace `origin`/`upstream` with your remote names if they differ.

   </details>

2. **Ensure overrides are up to date**

   ```sh
   # Confirm the list of layers I intend to keep across upgrades.
   cat custom/layers_to_preserve.json

   # Snapshot the current definitions for those layers.
   ./scripts/capture_layer_overrides.rb
   git status --short custom
   ```

   <details>
   <summary>Notes</summary>

   The first file should list every layer I want preserved (currently
   `QWERTY`, `Symbol`, and `World`). The capture script updates
   `custom/layer-overrides.json` with the latest bindings so merges and
   translations always have a fresh baseline. Commit any resulting JSON changes
   before proceeding.

   </details>

3. **Refresh my local mirror of upstream (`main`)**

   ```sh
   git checkout main
   git pull --ff-only upstream main   # or upstream/<release-tag>
   git push origin main               # keep my fork's main in sync (optional)
   ```

4. **Merge the refreshed main into my customization branch**

   ```sh
   git checkout bonanzi-de            # or the branch that holds my changes
   git merge main
   ```

   <details>
   <summary>Conflict tips</summary>

   - If a conflict touches `custom/layer-overrides.json`, choose the side that
     keeps the `LC(INS)`/`LS(INS)` bindings on the Symbol layer and the `de-DE`
     scancode entries on the World layer. After the merge finishes, rerun
     `./scripts/capture_layer_overrides.rb` to rebuild the snapshot so the JSON
     file matches the latest `keymap.json` layout.
   - Use `git status` to see unresolved files, `git add <file>` after fixing
     them, then `git merge --continue` to proceed. If something goes wrong,
     `git merge --abort` restores the pre-merge state.

   </details>

5. **Reapply the `de-DE` scancode translation**

   ```sh
   ./scripts/translate_to_de.rb
   ```

   <details>
   <summary>What this does</summary>

   This script rewrites `keymap.json`, `default.json`, and
   `custom/layer-overrides.json` with `de-DE` scancodes, updates `keymap.zmk`,
   and ensures the metadata reflects the German locale. Review any
   punctuation-heavy layers afterwards (either in the Glove80 editor or by
   inspecting the override JSON) to confirm the expected scancodes remain in
   place.

   </details>

6. **Regenerate artifacts**

   ```sh
   rake dtsi
   ```

   <details>
   <summary>Why</summary>

   This reruns the ERB template with upstream changes while reapplying the
   captured overrides and translation. If Ruby cannot find `rake`, install it
   with `gem install rake` and retry.

   </details>

7. **Upload to the Glove80 layout editor**

   1. Open `https://my.glove80.com` and log in.
   2. Enable "Use local config" and download a backup of your current layout.
   3. Copy the regenerated `keymap.dtsi` contents into the "Custom Defined
      Behaviors" editor.
   4. Build the firmware to generate a new `.uf2` bundle.

8. **Flash the keyboard**

   1. Put each half into bootloader storage mode (tap the reset button twice).
   2. Copy the new `.uf2` file onto both halves (right half optional for
      incremental updates).
   3. If the firmware version changed, perform the factory reset/re-pair
      sequence so Bluetooth reconnection works.

9. **Post-flash verification**

   - Test `Ctrl+Insert` and `Shift+Insert` on the Symbol layer to confirm copy
     and paste still work on Windows hosts.
   - Press the World layer key and send `ä`, `ö`, `ü`, and `ß` to ensure the
     dedicated `de-DE` scancodes generate the expected characters on host
     systems.

## 5. Troubleshooting tips

- **Missing layers during capture:** double-check spelling in
  `custom/layers_to_preserve.json`. The script prints missing names.
- **Ruby cannot find rake:** install it via `gem install rake` and make sure
  your shell profile exports Homebrew's Ruby path.
- **Glove80 editor rejects pasted DTSI:** ensure you copied from the generated
  `keymap.dtsi` after running `rake dtsi`; stale files may lack your overrides.
- **Merge conflicts in Symbol overrides:** treat `custom/layer-overrides.json`
  as a generated file. During a merge, pick your version with
  `git checkout --ours custom/layer-overrides.json`, complete the merge, then
  rerun `./scripts/capture_layer_overrides.rb` to regenerate a clean snapshot.
  This minimizes conflict noise even though the file contains customized keycodes
  such as `LC(INS)`.

## 6. Reference files in this fork

- `README.bonanzi.md` (this document)
- `custom/layers_to_preserve.json`
- `custom/layer-overrides.json`
- `scripts/capture_layer_overrides.rb`
- `keymap.dtsi.erb` (loads overrides during generation)

These components replace the old `Glorious_Engrammer-v36_de-v112_` export while
keeping all of my `de-DE`-specific customizations under version control.

## 7. Locale strategy and `de-DE` scancodes

### Locale selector vs. host keyboard layout

The Glove80 Layout Editor's locale selector serves two purposes: it redraws the
labels in the browser and decides which ZMK `&kp` scancodes end up in the JSON
export. Now that this fork intentionally ships `de-DE` scancodes, I flip the
selector to `de-DE` before exporting and leave macOS on the German input source.
The punctuation row therefore matches the physical legends and the base layer
produces umlauts/ß without extra compose shortcuts. When referencing Sunaku's
upstream diagrams, keep in mind that punctuation such as `-`, `/`, `[`, `]`,
`'`, and `;` moves compared to the original `en-US` layout.

If I temporarily need to compare against upstream behavior, I can still export
with the locale set to `en-US`, but doing so reintroduces the double-remapping
issues on a German host. In that case, remember to run the translation workflow
again before committing so the repository returns to the canonical `de-DE`
scancode configuration.

### Maintaining the `de-DE` scancode translation

Step 5 of the main workflow (`./scripts/translate_to_de.rb`) ensures every layer
stays encoded with `de-DE` scancodes and updates the related metadata. The
GitHub Actions workflow in `.github/workflows/translate-de.yml` runs the same
command for every push or pull request that touches the affected files, so CI
fails if the translation falls out of sync. After translating I review
punctuation-heavy layers in the editor or directly inside
`custom/layer-overrides.json` to ensure the generated scancodes match
expectations.

### Keeping custom layers across upgrades

Step 2 of the upgrade workflow explicitly checks `custom/layers_to_preserve.json`
and reruns `./scripts/capture_layer_overrides.rb` so my `QWERTY`, `Symbol`, and
`World` layers survive every upstream merge. Recapturing the overrides whenever
I tweak those layers keeps the JSON snapshot ready for the next upgrade.
