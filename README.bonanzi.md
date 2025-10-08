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

> **Why does the script touch `layer-overrides.json` instead of the online
> editor?** The Glove80 configurator cannot express some of my bindings (e.g.
> the Symbol layer's `LC(INS)`/`LS(INS)` copy-paste shortcuts), so those live
> only in `custom/layer-overrides.json`. When the capture script runs it merges
> the freshly exported layer with whatever is already in the overrides file,
> preserving any hand-edited entries that do not exist in `keymap.json`.

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

3. **Refresh my local mirror of upstream (`main`)**
   ```sh
   git checkout main
   git pull --ff-only upstream main   # or upstream/<release-tag>
   git push origin main               # keep my fork's main in sync (optional)
   ```

4. **Rebase my customization branch onto the refreshed main**
   ```sh
   git checkout bonanzi-de            # or the branch that holds my changes
   git rebase main
   ```
   While rebasing:

   - If a conflict touches `custom/layer-overrides.json`, choose the side that
     keeps the `LC(INS)`/`LS(INS)` bindings on the Symbol layer. After the
     rebase finishes, rerun `./scripts/capture_layer_overrides.rb` to rebuild
     the snapshot so the JSON file matches the latest `keymap.json` layout.
   - Use `git status` to see unresolved files, `git add <file>` after fixing
     them, then `git rebase --continue` to proceed. If something goes wrong,
     `git rebase --abort` restores the pre-rebase state.

5. **Regenerate artifacts**
   ```sh
   rake dtsi
   ```
   This reruns the ERB template with upstream changes while reapplying the
   captured overrides. If Ruby cannot find `rake`, install it with
   `gem install rake` and retry.

6. **Upload to the Glove80 layout editor**
   1. Open `https://my.glove80.com` and log in.
   2. Enable "Use local config" and download a backup of your current layout.
   3. Copy the regenerated `keymap.dtsi` contents into the "Custom Defined
      Behaviors" editor.
   4. Build the firmware to generate a new `.uf2` bundle.

7. **Flash the keyboard**
   1. Put each half into bootloader storage mode (tap the reset button twice).
   2. Copy the new `.uf2` file onto both halves (right half optional for
      incremental updates).
   3. If the firmware version changed, perform the factory reset/re-pair
      sequence so Bluetooth reconnection works.

8. **Post-flash verification**
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
- **Merge conflicts in Symbol overrides:** treat `custom/layer-overrides.json`
  as a generated file. During a rebase, pick your version with
  `git checkout --ours custom/layer-overrides.json`, complete the rebase, then
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
keeping all of my German-specific customizations under version control.
