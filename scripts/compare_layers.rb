#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

require_relative 'layer_utils'

DEFAULT_LEFT_SPEC = '4e473df4aff11ca5b1034ad896973843000b1b82:keymap.json'

options = {
  left: DEFAULT_LEFT_SPEC,
  right: LayerUtils.default_keymap_path.to_s,
  layers: [],
  friendly: true
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage: #{File.basename($PROGRAM_NAME)} [options]

    Compare one or more layers between two keymap JSON files. Paths can be
    regular files or Git object specifications (e.g. COMMIT:path/to/keymap.json).
  BANNER

  opts.on('--left SPEC', 'Left keymap file or Git spec (default: Glorious v36 export)') do |spec|
    options[:left] = spec
  end

  opts.on('--right SPEC', 'Right keymap file or Git spec (default: current keymap.json)') do |spec|
    options[:right] = spec
  end

  opts.on('--layer NAME', 'Layer to compare (can be repeated; defaults to QWERTY and Symbol)') do |name|
    options[:layers] << name
  end

  opts.on('--raw', 'Compare raw keycodes instead of friendly labels') do
    options[:friendly] = false
  end

  opts.on('-h', '--help', 'Show this help message and exit') do
    puts opts
    exit
  end
end

parser.parse!(ARGV)

layers_to_compare = options[:layers]
layers_to_compare = %w[QWERTY Symbol] if layers_to_compare.empty?

left_commit, left_path = LayerUtils.parse_spec(options[:left])
right_commit, right_path = LayerUtils.parse_spec(options[:right])

left_keymap = LayerUtils.load_keymap_spec(options[:left])
right_keymap = LayerUtils.load_keymap_spec(options[:right])

left_overrides = LayerUtils.load_overrides_spec(left_commit, left_path.dirname.join('custom', 'layer-overrides.json'))
right_overrides = LayerUtils.load_overrides_spec(right_commit, right_path.dirname.join('custom', 'layer-overrides.json'))

left_layer_names = left_keymap.fetch('layer_names')
right_layer_names = right_keymap.fetch('layer_names')
left_layers = left_keymap.fetch('layers')
right_layers = right_keymap.fetch('layers')

exit_status = 0

layers_to_compare.each do |identifier|
  left_index, left_name = LayerUtils.locate_layer(left_layer_names, identifier)
  right_index, right_name = LayerUtils.locate_layer(right_layer_names, identifier)

  left_layer = LayerUtils.merge_with_override(left_layers.fetch(left_index), left_overrides[left_name])
  left_layer = LayerUtils.translate_layer_to_de(left_layer)
  right_layer = LayerUtils.merge_with_override(right_layers.fetch(right_index), right_overrides[right_name])

  left_labels = LayerUtils.layer_labels(left_layer, friendly: options[:friendly])
  right_labels = LayerUtils.layer_labels(right_layer, friendly: options[:friendly])

  max_length = [left_labels.length, right_labels.length].max
  differences = []

  max_length.times do |idx|
    left_label = left_labels[idx] || ''
    right_label = right_labels[idx] || ''
    next if left_label == right_label

    differences << {
      index: idx,
      position: LayerUtils.position_description(idx),
      left: left_label,
      right: right_label
    }
  end

  if differences.empty?
    puts "#{left_name} layer matches #{right_name} (#{max_length} bindings)."
  else
    exit_status = 1
    puts "#{left_name} layer differs from #{right_name} (#{differences.length} mismatches):"
    if left_labels.length != right_labels.length
      puts "  Binding counts differ: left=#{left_labels.length}, right=#{right_labels.length}"
    end

    differences.each do |diff|
      left_text = diff[:left].empty? ? '∅' : diff[:left]
      right_text = diff[:right].empty? ? '∅' : diff[:right]
      puts format('  %-32s | left: %-10s | right: %-10s', diff[:position], left_text, right_text)
    end
  end
end

exit exit_status
