#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require 'fileutils'

repo_root = Pathname.new(__dir__).join('..').expand_path
keymap_path = repo_root.join('keymap.json')
config_path = repo_root.join('custom', 'layers_to_preserve.json')
overrides_path = repo_root.join('custom', 'layer-overrides.json')

abort "missing #{keymap_path}" unless keymap_path.file?
abort "missing #{config_path}" unless config_path.file?

keymap = JSON.parse(keymap_path.read)
layer_names = keymap.fetch('layer_names')
layers = keymap.fetch('layers')
names_to_preserve = JSON.parse(config_path.read)

unless names_to_preserve.is_a?(Array) && names_to_preserve.all? { |name| name.is_a?(String) }
  abort "#{config_path} must contain a JSON array of layer names"
end

# Keep a copy of the previously captured overrides so we can merge any
# hand-edited entries (for example, my Symbol layer's `LC(INS)` and
# `LS(INS)` bindings for Windows copy/paste). The exported `keymap.json`
# only contains whatever is in the online editor, so we need to preserve
# custom edits that live solely inside `custom/layer-overrides.json`.
existing_overrides =
  if overrides_path.file?
    JSON.parse(overrides_path.read)
  else
    {}
  end

existing_layers = existing_overrides.fetch('layers', {})

overrides = {}
missing = []

names_to_preserve.each do |name|
  index = layer_names.index(name)
  if index
    layer = layers[index]
    previous = existing_layers[name]

    overrides[name] =
      if previous.is_a?(Array) && layer.is_a?(Array)
        # Combine the freshly captured entries with any existing overrides
        # position-by-position. This keeps the current export in sync while
        # letting earlier JSON tweaks survive subsequent capture runs.
        layer.each_with_index.map do |entry, idx|
          previous.fetch(idx, entry)
        end + Array(previous[layer.length..])
      else
        layer
      end
  else
    missing << name
  end
end

FileUtils.mkdir_p(overrides_path.dirname)
overrides_path.write(JSON.pretty_generate({ 'layers' => overrides }) + "\n")

unless missing.empty?
  warn "Skipped missing layers: #{missing.join(', ')}"
end
