#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'pathname'

module LayerUtils
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

  SLOTS_PER_SIDE =
    LAYOUT_ROWS.flat_map { |row| [row[:left].length, row[:right].length] }.max

  FALLBACK_DEFAULT_LAYERS = %w[QWERTY Symbol].freeze

  FRIENDLY_KEYCODES = {
    'AMPS' => '&',
    'AT' => '@',
    'BACKSPACE' => 'Backsp',
    'BSPC' => 'Backsp',
    'BSLH' => '\\',
    'CARET' => '^',
    'COMMA' => ',',
    'COLON' => ':',
    'DEL' => 'Del',
    'DELETE' => 'Del',
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
    'DE_ACUT' => '´',
    'DLLR' => '$',
    'DQT' => '"',
    'EQUAL' => '=',
    'ESC' => 'Esc',
    'EXCL' => '!',
    'GRAVE' => '`',
    'FSLH' => '/',
    'HASH' => '#',
    'HOME' => 'Home',
    'INS' => 'Ins',
    'INSERT' => 'Ins',
    'LBRC' => '[',
    'LBKT' => '[',
    'LEFT' => 'Left',
    'LPAR' => '(',
    'MINUS' => '-',
    'MSC' => 'Mouse',
    'N0' => '0',
    'N1' => '1',
    'N2' => '2',
    'N3' => '3',
    'N4' => '4',
    'N5' => '5',
    'N6' => '6',
    'N7' => '7',
    'N8' => '8',
    'N9' => '9',
    'PAGE_UP' => 'PgUp',
    'PG_DN' => 'PgDn',
    'PG_UP' => 'PgUp',
    'PIPE' => '|',
    'PLUS' => '+',
    'PRCNT' => '%',
    'QMARK' => '?',
    'RBRC' => ']',
    'RBKT' => ']',
    'RET' => 'Enter',
    'ENTER' => 'Enter',
    'RIGHT' => 'Right',
    'RPAR' => ')',
    'RSHFT' => 'Shift',
    'SLASH' => '/',
    'SCRL_DOWN' => 'Scroll↓',
    'SCRL_UP' => 'Scroll↑',
    'SEMI' => ';',
    'SPACE' => 'Space',
    'SQT' => "'",
    'STAR' => '*',
    'TAB' => 'Tab',
    'TILDE' => '~',
    'UNDER' => '_',
    'UP' => 'Up',
    'DOWN' => 'Down',
    'DOT' => '.',
    'LT' => '<',
    'GT' => '>'
  }.freeze

  US_TO_DE_KEYCODES = {
    'GRAVE' => 'DE_CIRC',
    'N1' => 'DE_1',
    'N2' => 'DE_2',
    'N3' => 'DE_3',
    'N4' => 'DE_4',
    'N5' => 'DE_5',
    'N6' => 'DE_6',
    'N7' => 'DE_7',
    'N8' => 'DE_8',
    'N9' => 'DE_9',
    'N0' => 'DE_0',
    'MINUS' => 'DE_SS',
    'EQUAL' => 'DE_ACUT',
    'Q' => 'DE_Q',
    'W' => 'DE_W',
    'E' => 'DE_E',
    'R' => 'DE_R',
    'T' => 'DE_T',
    'Y' => 'DE_Z',
    'U' => 'DE_U',
    'I' => 'DE_I',
    'O' => 'DE_O',
    'P' => 'DE_P',
    'LBKT' => 'DE_UDIA',
    'RBKT' => 'DE_PLUS',
    'BSLH' => 'DE_HASH',
    'A' => 'DE_A',
    'S' => 'DE_S',
    'D' => 'DE_D',
    'F' => 'DE_F',
    'G' => 'DE_G',
    'H' => 'DE_H',
    'J' => 'DE_J',
    'K' => 'DE_K',
    'L' => 'DE_L',
    'SEMI' => 'DE_ODIA',
    'SQT' => 'DE_ADIA',
    'Z' => 'DE_Y',
    'X' => 'DE_X',
    'C' => 'DE_C',
    'V' => 'DE_V',
    'B' => 'DE_B',
    'N' => 'DE_N',
    'M' => 'DE_M',
    'COMMA' => 'DE_COMMA',
    'DOT' => 'DE_DOT',
    'SLASH' => 'DE_MINUS',
    'FSLH' => 'DE_MINUS',
    'LT' => 'DE_LABK'
  }.freeze

  US_SPECIAL_TRANSLATIONS = {
    'GT' => lambda do
      {
        'value' => 'LS',
        'params' => [
          { 'value' => 'DE_LABK', 'params' => [] }
        ]
      }
    end
  }.freeze

  module_function

  def default_keymap_path
    Pathname.new(__dir__).join('..', 'keymap.json')
  end

  def parse_spec(spec)
    return [nil, Pathname.new(spec)] unless spec.is_a?(String)

    if spec.include?(':') && !Pathname.new(spec).exist?
      commit, path = spec.split(':', 2)
      [commit, Pathname.new(path)]
    else
      [nil, Pathname.new(spec)]
    end
  end

  def git_show(spec)
    stdout, stderr, status = Open3.capture3('git', 'show', spec)
    raise "git show #{spec} failed: #{stderr.strip}" unless status.success?

    stdout
  end

  def load_keymap(path)
    path = Pathname.new(path)
    JSON.parse(path.expand_path.read)
  rescue Errno::ENOENT
    abort "missing keymap file: #{path}"
  rescue JSON::ParserError => e
    abort "failed to parse #{path}: #{e.message}"
  end

  def load_keymap_spec(spec)
    commit, path = parse_spec(spec)
    if commit
      json = git_show("#{commit}:#{path}")
      JSON.parse(json)
    else
      load_keymap(path)
    end
  rescue JSON::ParserError => e
    abort "failed to parse #{spec}: #{e.message}"
  rescue RuntimeError => e
    abort e.message
  end

  def load_overrides(path)
    path = Pathname.new(path)
    return {} unless path.file?

    data = JSON.parse(path.read)
    data.fetch('layers', {})
  rescue JSON::ParserError => e
    warn "warning: failed to parse overrides at #{path}: #{e.message}"
    {}
  end

  def load_overrides_spec(commit, path)
    path = Pathname.new(path)
    if commit
      spec = "#{commit}:#{path}"
      begin
        json = git_show(spec)
      rescue RuntimeError
        return {}
      end
      begin
        JSON.parse(json).fetch('layers', {})
      rescue JSON::ParserError => e
        warn "warning: failed to parse overrides at #{spec}: #{e.message}"
        {}
      end
    else
      load_overrides(path)
    end
  end

  def detect_default_layers(layer_names, keymap_path)
    defaults = []

    preserve_path = keymap_path.dirname.join('custom', 'layers_to_preserve.json')
    if preserve_path.file?
      begin
        data = JSON.parse(preserve_path.read)
        preserved = Array(data['layers']).map(&:to_s)
        preserved.each do |name|
          defaults << name if layer_names.any? { |candidate| candidate.casecmp?(name) }
        end
      rescue JSON::ParserError => e
        warn "warning: failed to parse preserved layers at #{preserve_path}: #{e.message}"
      end
    end

    defaults = FALLBACK_DEFAULT_LAYERS if defaults.empty?

    defaults.select do |name|
      layer_names.any? { |candidate| candidate.casecmp?(name) }
    end
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

  def translate_structure_to_de(object)
    case object
    when Array
      object.map { |item| translate_structure_to_de(item) }
    when Hash
      translated = object.transform_values { |value| translate_structure_to_de(value) }
      translate_node_to_de(translated)
    else
      object
    end
  end

  def translate_node_to_de(hash)
    return hash unless hash.is_a?(Hash)

    if (transform = US_SPECIAL_TRANSLATIONS[hash['value']])
      return translate_structure_to_de(transform.call)
    end

    if (replacement = US_TO_DE_KEYCODES[hash['value']])
      hash = hash.merge('value' => replacement)
    end

    hash
  end

  def translate_layer_to_de(layer)
    translate_structure_to_de(layer)
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

  def layer_labels(layer, friendly: true)
    layer.map { |entry| format_node(entry, friendly: friendly).strip }
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

  def position_for(index)
    LAYOUT_ROWS.each_with_index do |row, row_idx|
      row.each do |side, slots|
        col_idx = slots.index(index)
        return { side: side, row: row_idx, col: col_idx } if col_idx
      end
    end
    nil
  end

  def position_description(index)
    meta = position_for(index)
    return "index #{index}" unless meta

    side = meta[:side] == :left ? 'Left' : 'Right'
    row = meta[:row] + 1
    col = meta[:col] + 1
    "#{side} row #{row}, column #{col} (index #{index})"
  end
end
