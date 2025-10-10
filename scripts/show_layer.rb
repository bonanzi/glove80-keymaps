#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

require_relative 'layer_utils'

def parse_options(argv, layer_names_for_usage)
  options = {
    keymap_path: LayerUtils.default_keymap_path,
    mode: :standard,
    cell_width: LayerUtils::CELL_WIDTH,
    list: false,
    positions: false,
    friendly_labels: true,
    layers: []
  }

  OptionParser.new do |parser|
    usage_layers = if layer_names_for_usage.empty?
                     '  (no layers available)'
                   else
                     layer_names_for_usage.each_slice(6).map do |group|
                       "  #{group.join(', ')}"
                     end.join("\n")
                   end

    parser.banner = <<~BANNER
      Usage: #{File.basename($PROGRAM_NAME)} [options] [--layer NAME ...]

      Available layers:
#{usage_layers}
    BANNER

    parser.on('-f', '--file PATH', 'Path to keymap JSON (default: keymap.json)') do |path|
      options[:keymap_path] = Pathname.new(path)
    end

    parser.on('-m', '--mirror', 'Display mirrored layout positions only') do
      options[:mode] = :mirrored
    end

    parser.on('-b', '--both', 'Display both standard and mirrored layouts') do
      options[:mode] = :both
    end

    parser.on('-w', '--width N', Integer, 'Cell width (default: 7)') do |width|
      options[:cell_width] = [width, 2].max
    end

    parser.on('-l', '--list', 'List available layers and exit') do
      options[:list] = true
    end

    parser.on('-p', '--positions', 'Show physical key positions instead of bindings') do
      options[:positions] = true
    end

    parser.on('--layer NAME', 'Render the specified layer (can be repeated)') do |layer|
      options[:layers] << layer
    end

    parser.on('--keycodes', 'Show raw keycodes instead of friendly labels') do
      options[:friendly_labels] = false
    end

    parser.on('-h', '--help', 'Show this help message') do
      puts parser
      exit
    end
  end.parse!(argv)

  options
end
default_keymap_path = LayerUtils.default_keymap_path
default_layer_names = begin
  LayerUtils.load_keymap(default_keymap_path).fetch('layer_names')
rescue StandardError
  []
end

options = parse_options(ARGV, default_layer_names)
keymap = LayerUtils.load_keymap(options[:keymap_path])
layer_names = keymap.fetch('layer_names')
layers = keymap.fetch('layers')

overrides_path = options[:keymap_path].dirname.join('custom', 'layer-overrides.json')
overrides = LayerUtils.load_overrides(overrides_path)

if options[:list]
  layer_names.each_with_index do |name, index|
    puts format('%2d: %s', index, name)
  end
  exit
end

identifiers = options[:layers] + ARGV
if identifiers.empty?
  identifiers = LayerUtils.detect_default_layers(layer_names, options[:keymap_path])
  identifiers = [layer_names.first] if identifiers.empty? && layer_names.any?
end

identifiers.each_with_index do |identifier, idx|
  layer_index, layer_name = LayerUtils.locate_layer(layer_names, identifier)
  layer = layers.fetch(layer_index)
  layer = LayerUtils.merge_with_override(layer, overrides[layer_name])

  puts if idx.positive?
  puts "Layer ##{layer_index}: #{layer_name}"

  tables =
    case options[:mode]
    when :mirrored
      [true]
    when :both
      [false, true]
    else
      [false]
    end

  tables.each_with_index do |mirrored, table_idx|
    puts if table_idx.positive?
    puts LayerUtils.render_table(
      layer,
      mirrored: mirrored,
      cell_width: options[:cell_width],
      show_positions: options[:positions],
      friendly: options[:friendly_labels]
    )
  end
end
