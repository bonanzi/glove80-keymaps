# keymap.dtsi comparison with Sunaku upstream

This note highlights the behavioral differences between the checked-in `keymap.dtsi` on the `work` branch and Sunaku's upstream layout (commit `fcc8c36`). The diff was generated with `git diff fcc8c36 keymap.dtsi`.

## Top-level configuration macros

* The fork targets macOS by default (`OPERATING_SYSTEM 'M'`), while Sunaku keeps Linux as the default. The fork also turns on mouse keys and natural scrolling from the outset. 【F:keymap.dtsi†L1-L12】
* Tapping resolution defaults to 250 ms instead of 150 ms, lengthening the hold thresholds throughout the mod-tap timing macros. 【F:keymap.dtsi†L872-L889】

## Engram layers prepared for a non-Engram build

* Both Engrammer and Engram layers now mirror the Enthium bindings so toggling them no longer changes the alphas before the next build; their layer blocks reuse the Enthium layout, differing only by layer identifier. 【F:keymap.zmk†L11244-L11275】
* The Layout Editor export renames those layers to make the duplication explicit for the upcoming non-Engram build. 【F:keymap.json†L35-L36】

## Regenerating `keymap.dtsi` without the Engram layer

1. Export the updated layout from the Glove80 Layout Editor (enable local config in Advanced Settings and use **Download**) so the JSON reflects the Engram layer removal. 【F:README.md†L939-L942】
2. Overwrite this repository's `keymap.json` with that export and run `rake` to rebuild the firmware snippets. 【F:README.md†L944-L946】
3. Copy the regenerated `keymap.dtsi` back into the Layout Editor's **Custom Defined Behaviors** field before building. 【F:README.md†L948-L949】

## Engram shift bindings

The number-row and punctuation morphs translate to German scancodes (`DE_*`) and AltGr chords, whereas Sunaku leaves them on US ANSI keycodes.

| Behavior | Fork binding | Sunaku binding |
| --- | --- | --- |
| `engram_N1` | `<&kp DE_1>, <&kp RA(DE_LABK)>` | `<&kp N1>, <&kp PIPE>` |
| `engram_N2` | `<&kp DE_2>, <&kp LS(DE_0)>` | `<&kp N2>, <&kp EQUAL>` |
| `engram_N3` | `<&kp DE_3>, <&kp RA(DE_PLUS)>` | `<&kp N3>, <&kp TILDE>` |
| `engram_N4` | `<&kp DE_4>, <&kp DE_PLUS>` | `<&kp N4>, <&kp PLUS>` |
| `engram_N7` | `<&kp DE_7>, <&kp DE_CIRC>` | `<&kp N7>, <&kp CARET>` |
| `engram_N8` | `<&kp DE_8>, <&kp LS(DE_6)>` | `<&kp N8>, <&kp AMPS>` |
| `engram_N9` | `<&kp DE_9>, <&kp LS(DE_5)>` | `<&kp N9>, <&kp PRCNT>` |
| `engram_N0` | `<&kp DE_0>, <&kp LS(DE_PLUS)>` | `<&kp N0>, <&kp STAR>` |
| `engram_SQT` | `<&kp LS(DE_HASH)>, <&kp LS(DE_8)>` | `<&kp SQT>, <&kp LPAR>` |
| `engram_DQT` | `<&kp LS(DE_2)>, <&kp LS(DE_9)>` | `<&kp DQT>, <&kp RPAR>` |
| `engram_COMMA` | `<&kp DE_COMMA>, <&kp LS(DE_COMMA)>` | `<&kp COMMA>, <&kp SEMI>` |
| `engram_DOT` | `<&kp DE_DOT>, <&kp LS(DE_DOT)>` | `<&kp DOT>, <&kp COLON>` |
| `engram_QMARK` | `<&kp LS(DE_SS)>, <&kp LS(DE_1)>` | `<&kp QMARK>, <&kp EXCL>` |
| `engram_HASH` | `<&kp DE_HASH>, <&kp LS(DE_4)>` | `<&kp HASH>, <&kp DLLR>` |
| `engram_AT` | `<&kp RA(DE_Q)>, <&kp RA(DE_ACUT)>` | `<&kp AT>, <&kp GRAVE>` |
| `engram_FSLH` | `<&kp LS(DE_7)>, <&kp RA(DE_SS)>` | `<&kp FSLH>, <&kp BSLH>` |

(See `keymap.dtsi` lines 3136–3243 for the fork's bindings and the same section in Sunaku's layout for the upstream values.) 【F:keymap.dtsi†L3136-L3243】

## Unicode helpers for umlauts and ß

Unicode behaviors for `ä`, `ö`, `ü`, and `ß` remain identical to upstream; no additional changes are necessary for these characters. For example, `world_a_diaeresis_lower` still emits macOS compose `⌥U, A` when compose mode is enabled. 【F:keymap.dtsi†L4962-L4985】
