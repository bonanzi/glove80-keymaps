# Bonanzi's Glove80 fork guide

This document collects everything specific to my German QWERTY fork of
Sunaku's "Glorious Engrammer" layout. It explains the tooling you need on macOS,
which layers are preserved across upgrades, and the exact workflow for rebasing
onto new upstream releases while keeping my Symbol-layer Insert shortcuts and
World-layer German characters intact.

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
- `World` (Compose-aware German characters and ß)

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

## 4. Detailed upgrade tutorial

Follow these steps whenever Sunaku publishes a new release that I want to adopt.
This workflow keeps my branch rebased onto upstream while fast-forward merges
remain possible.

1. **Sync remotes**
   ```sh
   git fetch origin
   git fetch upstream
   ```
   Replace `origin`/`upstream` with your remote names if they differ.

2. **Ensure overrides are up to date**
   ```sh
   ./scripts/capture_layer_overrides.rb
   git status --short custom
   ```
   Commit any resulting JSON changes so my preserved layers match the current
   layout before rebasing.

3. **Rebase onto the new upstream tag/commit**
   ```sh
   git switch dev-bobo          # my customization branch
   git rebase upstream/main   # or upstream/<release-branch>
   ```
   Resolve conflicts as they appear. When `custom/layer-overrides.json` conflicts
   with upstream, keep the version that contains `LC(INS)` and `LS(INS)` on the
   Symbol layer so the Windows copy/paste shortcuts remain intact.

4. **Regenerate artifacts**
   ```sh
   rake dtsi
   ```
   This reruns the ERB template with upstream changes while reapplying the
   captured overrides. If Ruby cannot find `rake`, install it with
   `gem install rake` and retry.

5. **Upload to the Glove80 layout editor**
   1. Open `https://my.glove80.com` and log in.
   2. Enable "Use local config" and download a backup of your current layout.
   3. Copy the regenerated `keymap.dtsi` contents into the "Custom Defined
      Behaviors" editor.
   4. Build the firmware to generate a new `.uf2` bundle.

6. **Flash the keyboard**
   1. Put each half into bootloader storage mode (tap the reset button twice).
   2. Copy the new `.uf2` file onto both halves (right half optional for
      incremental updates).
   3. If the firmware version changed, perform the factory reset/re-pair
      sequence so Bluetooth reconnection works.

7. **Post-flash verification**
   - Test `Ctrl+Insert` and `Shift+Insert` on the Symbol layer to confirm copy
     and paste still work on Windows hosts.
   - Press the World layer key and send `ä`, `ö`, `ü`, and `ß` to ensure the
     OS-aware macros load correctly.

## 5. Troubleshooting tips

- **Missing layers during capture:** double-check spelling in
  `custom/layers_to_preserve.json`. The script prints missing names.
- **Ruby cannot find rake:** install it via `gem install rake` and make sure
  your shell profile exports Homebrew's Ruby path.
- **Glove80 editor rejects pasted DTSI:** ensure you copied from the generated
  `keymap.dtsi` after running `rake dtsi`; stale files may lack your overrides.

## 6. Reference files in this fork

- `README.bonanzi.md` (this document)
- `custom/layers_to_preserve.json`
- `custom/layer-overrides.json`
- `scripts/capture_layer_overrides.rb`
- `keymap.dtsi.erb` (loads overrides during generation)

These components replace the old `Glorious_Engrammer-v36_de-v112_` export while
keeping all of my German-specific customizations under version control.
