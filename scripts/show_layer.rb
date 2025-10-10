#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'pathname'

CELL_WIDTH = 7
SPACE_BETWEEN_SLOTS = ' '

LAYOUT_ROWS = [
  { left: [nil, 0, 1, 2, 3, 4, nil], right: [nil, nil, 5, 6, 7, 8, 9] },
  { left: [10, 11, 12, 13, 14, 15, nil], right: [16, 17, 18, 19, 20, 21, nil] },
  { left: [22, 23, 24, 25, 26, 27, nil], right: [28, 29, 30, 31, 32, 33, nil] },
  { left: [34, 35, 36, 37, 38, 39, nil], right: [40, 41, 42, 43, 44, 45, nil] },
  { left: [46, 47, 48, 49, 50, 51, nil], right: [58, 59, 60, 61, 62, 63, nil] },
  { left: [nil, 64, 65, 66, 67, 68, nil], right: [nil, nil, 75, 76, 77, 78, 79] },
  { left: [nil, nil, nil, 69, 52, nil, nil], right: [nil, nil, nil, 57, 74, nil, nil] },
  { left: [nil, nil, nil, 70, 53, nil, nil], right: [nil, nil, nil, 56, 73, nil, nil] },
  { left: [nil, nil, nil, 71, 54, nil, nil], right: [nil, nil, nil, 55, 72, nil, nil] }
].freeze

SLOTS_PER_SIDE =
  LAYOUT_ROWS.flat_map { |row| [row[:left].length, row[:right].length] }.max

module LayerLayout
  module_function

  def build_mirror_map(rows)
    rows.each_with_object({}) do |row, map|
      left_positions = row[:left].compact
      right_positions = row[:right].compact.reverse
      left_positions.zip(right_positions).each do |left_pos, right_pos|
        next unless left_pos && right_pos

        map[left_pos] = right_pos
        map[right_pos] = left_pos
      end
    end
  end

  MIRROR_MAP = build_mirror_map(LAYOUT_ROWS).freeze

  MIRRORED_ROWS = LAYOUT_ROWS.map do |row|
    {
      left: row[:left].map { |pos| pos && MIRROR_MAP[pos] },
      right: row[:right].map { |pos| pos && MIRROR_MAP[pos] }
    }
  end.freeze

  def rows(mirrored: false)
    mirrored ? MIRRORED_ROWS : LAYOUT_ROWS
  end
end

FALLBACK_DEFAULT_LAYERS = %w[QWERTY Symbol].freeze

FRIENDLY_KEYCODES = {
  'DE_0' => '0',
  'DE_1' => '1',
  'DE_2' => '2',
  'DE_3' => '3',
  'DE_4' => '4',
  'DE_5' => '5',
  'DE_6' => '6',
  'DE_7' => '7',
  'DE_8' => '8',
  'DE_9' => '9',
  'DE_A' => 'A',
  'DE_B' => 'B',
  'DE_C' => 'C',
  'DE_D' => 'D',
  'DE_E' => 'E',
  'DE_F' => 'F',
  'DE_G' => 'G',
  'DE_H' => 'H',
  'DE_I' => 'I',
  'DE_J' => 'J',
  'DE_K' => 'K',
  'DE_L' => 'L',
  'DE_M' => 'M',
  'DE_N' => 'N',
  'DE_O' => 'O',
  'DE_P' => 'P',
  'DE_Q' => 'Q',
  'DE_R' => 'R',
  'DE_S' => 'S',
  'DE_T' => 'T',
  'DE_U' => 'U',
  'DE_V' => 'V',
  'DE_W' => 'W',
  'DE_X' => 'X',
  'DE_Y' => 'Y',
  'DE_Z' => 'Z',
  'DE_ADIA' => 'Ä',
  'DE_ODIA' => 'Ö',
  'DE_UDIA' => 'Ü',
  'DE_SS' => 'ß',
  'DE_PLUS' => '+',
  'DE_MINUS' => '-',
  'DE_HASH' => '#',
  'DE_LABK' => '<',
  'DE_COMMA' => ',',
  'DE_DOT' => '.',
  'DE_CIRC' => '^',
  'DE_ACUT' => '´'
}.freeze

def parse_options(argv, layer_names_for_usage)
  options = {
    keymap_path: Pathname.new(__dir__).join('..', 'keymap.json'),
    mode: :standard,
    cell_width: CELL_WIDTH,
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

def load_keymap(path)
  JSON.parse(path.expand_path.read)
rescue Errno::ENOENT
  abort "missing keymap file: #{path}"
rescue JSON::ParserError => e
  abort "failed to parse #{path}: #{e.message}"
end

def load_overrides(path)
  return {} unless path.file?

  data = JSON.parse(path.read)
  data.fetch('layers', {})
rescue JSON::ParserError => e
  warn "warning: failed to parse overrides at #{path}: #{e.message}"
  {}
end

def detect_default_layers(layer_names, keymap_path)
  defaults = []

  preserve_path = keymap_path.dirname.join('custom', 'layers_to_preserve.json')
  if preserve_path.file?
    begin
      preserved = JSON.parse(preserve_path.read)
      if preserved.is_a?(Array)
        base_layer = preserved.find do |name|
          !name.casecmp?('symbol') &&
            layer_names.any? { |candidate| candidate.casecmp?(name) }
        end
        symbol_layer = preserved.find do |name|
          name.casecmp?('symbol') &&
            layer_names.any? { |candidate| candidate.casecmp?(name) }
        end

        defaults << base_layer if base_layer
        defaults << symbol_layer if symbol_layer &&
                                   defaults.none? { |name| name.casecmp?(symbol_layer) }
      end
    rescue JSON::ParserError => e
      warn "warning: failed to parse default layer list at #{preserve_path}: #{e.message}"
    end
  end

  if defaults.empty?
    defaults = FALLBACK_DEFAULT_LAYERS.select do |name|
      layer_names.any? { |candidate| candidate.casecmp?(name) }
    end
  end

  defaults
end

def locate_layer(layer_names, identifier)
  if identifier.match?(/\A\d+\z/)
    index = identifier.to_i
    return [index, layer_names[index]] if layer_names[index]
  else
    index = layer_names.find_index { |name| name.casecmp?(identifier) }
    return [index, layer_names[index]] if index
  end

  abort "unknown layer: #{identifier.inspect}"
end

def merge_with_override(layer, override)
  return layer unless override.is_a?(Array)

  layer.each_with_index.map do |entry, index|
    override.fetch(index, entry)
  end + Array(override[layer.length..])
end

def friendly_label(label)
  FRIENDLY_KEYCODES.fetch(label) do
    label.start_with?('DE_') ? label.delete_prefix('DE_') : label
  end
end

def format_node(node, friendly: true)
  return '' unless node

  value = node['value']
  params = node['params'] || []

  case value
  when '&none'
    ''
  when '&trans'
    'TRANS'
  when '&kp', '&sk'
    params.empty? ? 'KP' : format_node(params.first, friendly: friendly)
  when 'Custom'
    params.empty? ? 'Custom' : params.map { |param| format_node(param, friendly: friendly) }.join(' ')
  else
    label = value.start_with?('&') ? value.delete_prefix('&').upcase : value
    label = friendly_label(label) if friendly
    if params.empty?
      label
    else
      inner = params.map { |param| format_node(param, friendly: friendly) }.reject(&:empty?).join(', ')
      inner.empty? ? label : "#{label}(#{inner})"
    end
  end
end

def truncate(text, width)
  stripped = text.to_s.strip
  return '' if stripped.empty?
  return stripped if stripped.length <= width

  ellipsis = '…'
  slice = stripped[0, width - ellipsis.length]
  slice + ellipsis
end

def render_side(slots, layer, cell_width, show_positions:, friendly:)
  slots.map do |pos|
    if pos.nil?
      ' ' * cell_width
    elsif show_positions
      truncate(pos.to_s, cell_width).ljust(cell_width)
    else
      entry = layer[pos]
      truncate(format_node(entry, friendly: friendly), cell_width).ljust(cell_width)
    end
  end.join(SPACE_BETWEEN_SLOTS)
end

def render_table(layer, mirrored:, cell_width:, show_positions: false, friendly: true)
  rows = LayerLayout.rows(mirrored: mirrored)
  left_width = SLOTS_PER_SIDE * cell_width + (SLOTS_PER_SIDE - 1) * SPACE_BETWEEN_SLOTS.length
  right_width = left_width
  divider = "|#{'-' * (left_width + 2)}|#{'-' * (right_width + 2)}|"

  header_left = mirrored ? 'LEFT HAND (mirrored)' : 'LEFT HAND'
  header_right = mirrored ? 'RIGHT HAND (mirrored)' : 'RIGHT HAND'
  if show_positions
    header_left += ' positions'
    header_right += ' positions'
  end
  header = format("| %-#{left_width}s | %-#{right_width}s |", header_left, header_right)

  lines = rows.map do |row|
    left = render_side(row[:left], layer, cell_width, show_positions: show_positions, friendly: friendly)
    right = render_side(row[:right], layer, cell_width, show_positions: show_positions, friendly: friendly)
    format("| %-#{left_width}s | %-#{right_width}s |", left.rstrip, right.rstrip)
  end

  [divider, header, divider, lines, divider].flatten.join("\n")
end

default_keymap_path = Pathname.new(__dir__).join('..', 'keymap.json')
default_layer_names = begin
  load_keymap(default_keymap_path).fetch('layer_names')
rescue StandardError
  []
end

options = parse_options(ARGV, default_layer_names)
keymap = load_keymap(options[:keymap_path])
layer_names = keymap.fetch('layer_names')
layers = keymap.fetch('layers')

overrides_path = options[:keymap_path].dirname.join('custom', 'layer-overrides.json')
overrides = load_overrides(overrides_path)

if options[:list]
  layer_names.each_with_index do |name, index|
    puts format('%2d: %s', index, name)
  end
  exit
end

identifiers = options[:layers] + ARGV
if identifiers.empty?
  identifiers = detect_default_layers(layer_names, options[:keymap_path])
  identifiers = [layer_names.first] if identifiers.empty? && layer_names.any?
end

identifiers.each_with_index do |identifier, idx|
  layer_index, layer_name = locate_layer(layer_names, identifier)
  layer = layers.fetch(layer_index)
  layer = merge_with_override(layer, overrides[layer_name])

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
    puts render_table(
      layer,
      mirrored: mirrored,
      cell_width: options[:cell_width],
      show_positions: options[:positions],
      friendly: options[:friendly_labels]
    )
  end
end
