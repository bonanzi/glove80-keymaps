# Bonanzi's Glove80 fork guide

This guide covers my `de-DE` QWERTY fork of Sunaku's "Glorious Engrammer"
layout. It lists the macOS tooling, the layers I preserve, and the steps I use
to merge upstream releases while keeping Symbol-layer Insert shortcuts and
World-layer `de-DE` scancodes.

> **TL;DR:** Keep `main` fast-forwarded from upstream, capture overrides before
> merging, run `rake dtsi`, then flash the new `.uf2` and confirm the Symbol and
> World layers still send the expected shortcuts and scancodes.

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

I always preserve these customized layers:

- `QWERTY` (German base layer)
- `Symbol` (Insert-cluster copy/paste sends Ctrl+Insert and Shift+Insert)
- `World` (direct `de-DE` scancodes for umlauts and ß)

Both helper files live in `custom/`:

- `custom/layers_to_preserve.json` lists the layer names to snapshot.
- `custom/layer-overrides.json` stores the captured layouts.

After editing those layers in `keymap.json`, recapture the snapshot so the
override file matches the latest layout.

## 3. Capturing overrides

Run this helper script from the repo root to keep overrides current:

```sh
./scripts/capture_layer_overrides.rb
```

The script expects `keymap.json` and `custom/layers_to_preserve.json`. It updates
`custom/layer-overrides.json` and warns about any missing layer names. Commit
both JSON files together.

<details>
<summary>Why capture overrides locally instead of the online editor?</summary>

The Glove80 configurator cannot express some bindings (like the Symbol layer's
`LC(INS)`/`LS(INS)` shortcuts), so they live only in `custom/layer-overrides.json`.
The capture script merges the fresh export with the existing overrides and keeps
hand-edited entries that are absent from `keymap.json`.

</details>

## 4. Upgrade workflow (new upstream releases)

Use this compact checklist whenever Sunaku publishes a new release that I want
to merge into my customization branch:

```sh
# Keep tracking branches current.
git fetch origin
git fetch upstream
git checkout main
git pull --ff-only upstream main
git push origin main        # optional mirror of the pristine branch

# Capture the layers I preserve between releases.
cat custom/layers_to_preserve.json
./scripts/capture_layer_overrides.rb
git status --short custom   # commit JSON changes before proceeding

# Merge upstream into my working branch and rebuild artifacts.
git checkout bonanzi-de     # or whichever branch holds my tweaks
git merge main              # resolve conflicts, keeping Symbol/World overrides
./scripts/translate_to_de.rb
rake dtsi

# Ship the new firmware.
#  - Paste keymap.dtsi into https://my.glove80.com and build a fresh .uf2
#  - Flash both halves (double-tap reset, copy the .uf2)
#  - Verify Symbol copy/paste and World-layer umlauts/ß on the host
```

### Understanding the branches I keep around

- `main`: pristine mirror of Sunaku's repo; always fast-forward from upstream.
- `bonanzi-de`: working branch with my Symbol and World tweaks.
- Scratch branches: short-lived experiments that merge back into `bonanzi-de`.

If a merge touches `custom/layer-overrides.json`, keep the entries with
`LC(INS)`, `LS(INS)`, and the `de-DE` scancode names. After resolving conflicts,
rerun `./scripts/capture_layer_overrides.rb` so the snapshot matches
`keymap.json`.

## 5. Troubleshooting tips

- **Missing layers during capture:** check spelling in
  `custom/layers_to_preserve.json`; the script prints any missing names.
- **Ruby cannot find rake:** run `gem install rake` and ensure your shell profile
  exports Homebrew's Ruby path.
- **Glove80 editor rejects pasted DTSI:** copy from the freshly generated
  `keymap.dtsi` after `rake dtsi`; stale files may drop overrides.
- **Merge conflicts in Symbol overrides:** treat `custom/layer-overrides.json`
  as generated. Choose `ours`, finish the merge, then rerun
  `./scripts/capture_layer_overrides.rb` to regenerate the snapshot.

## 6. Reference files in this fork

- `README.bonanzi.md` (this document)
- `custom/layers_to_preserve.json`
- `custom/layer-overrides.json`
- `scripts/capture_layer_overrides.rb`
- `keymap.dtsi.erb` (loads overrides during generation)

Together these files replace the old `Glorious_Engrammer-v36_de-v112_` export
while keeping every `de-DE` customization in version control.

## 7. Locale strategy and `de-DE` scancodes

### Locale selector vs. host keyboard layout

The Glove80 editor's locale selector redraws labels and chooses the ZMK `&kp`
scancodes in the export. Because this fork ships `de-DE` scancodes, I export
with the selector on `de-DE` and leave macOS on the German input source. That
keeps the punctuation row aligned with the key legends and sends umlauts/ß
without compose shortcuts. When comparing to Sunaku's diagrams, remember that
characters like `-`, `/`, `[`, `]`, `'`, and `;` move relative to `en-US`.

For quick upstream comparisons I can export with `en-US`, but that reintroduces
double-remapping on a German host. Afterward I always rerun the translation
workflow so the repo returns to the canonical `de-DE` scancodes.

### Maintaining the `de-DE` scancode translation

Step 5 of the workflow (`./scripts/translate_to_de.rb`) keeps every layer on
`de-DE` scancodes and updates metadata. GitHub Actions runs the same command via
`.github/workflows/translate-de.yml`, so CI fails if the translation drifts. I
spot-check punctuation-heavy layers in the editor or in
`custom/layer-overrides.json` to confirm the generated scancodes.

### Keeping custom layers across upgrades

Step 2 of the upgrade workflow rechecks `custom/layers_to_preserve.json` and reruns
`./scripts/capture_layer_overrides.rb` so my `QWERTY`, `Symbol`, and `World`
layers survive every merge. Recapturing after each tweak keeps the JSON snapshot
ready for the next upgrade.

## Compact workflow: pinning to Sunaku release v40

When I need to align my branch with an older upstream tag (e.g. Sunaku's v40)
while keeping all `de-DE` customizations, this abbreviated sequence is enough:

```sh
# 1. Save my customized layers before switching releases.
./scripts/capture_layer_overrides.rb
git status --short custom

# 2. Move the local mirror of upstream to the desired tag.
git checkout main
git pull --ff-only upstream v40

# 3. Merge the release into my customization branch and resolve conflicts.
git checkout bonanzi-de
git merge main

# 4. Reapply locale translation and rebuild generated artifacts.
./scripts/translate_to_de.rb
rake dtsi
```

Afterward I upload the refreshed `keymap.dtsi` to the Glove80 editor, export the
firmware, and flash both halves as described earlier.
