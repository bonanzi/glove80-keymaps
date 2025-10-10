#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'

REPO_ROOT = Pathname.new(__dir__).join('..').expand_path

KEYCODE_MAP = {
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

SPECIAL_MAPPINGS = {
  'GT' => lambda do
    {
      'value' => 'LS',
      'params' => [
        { 'value' => 'DE_LABK', 'params' => [] }
      ]
    }
  end
}.freeze

TARGET_JSON_FILES = [
  REPO_ROOT.join('keymap.json'),
  REPO_ROOT.join('default.json'),
  REPO_ROOT.join('custom', 'layer-overrides.json')
].freeze

TARGET_TEXT_FILES = [
  REPO_ROOT.join('keymap.zmk')
].freeze

INDENT = '  '

def translate_structure(object)
  case object
  when Array
    object.map { |item| translate_structure(item) }
  when Hash
    translated = object.transform_values { |value| translate_structure(value) }
    translate_node(translated)
  else
    object
  end
end

def translate_node(hash)
  return hash unless hash.is_a?(Hash)

  if (transform = SPECIAL_MAPPINGS[hash['value']])
    return translate_structure(transform.call)
  end

  if (replacement = KEYCODE_MAP[hash['value']])
    hash = hash.merge('value' => replacement)
  end

  hash
end

def translate_json_file(path)
  data = JSON.parse(path.read)
  data['locale'] = 'de-DE' if data.is_a?(Hash) && data.key?('locale')
  translated = translate_structure(data)
  json = JSON.pretty_generate(translated, indent: INDENT)
  json << "\n" unless json.end_with?("\n")
  path.write(json)
end

TOKEN_BOUNDARY = /(?=[^A-Z0-9_])/ # next character that is not part of an identifier

def translate_text_file(path)
  content = path.read
  KEYCODE_MAP.each do |from, to|
    pattern = /(&kp\s+)#{Regexp.escape(from)}#{TOKEN_BOUNDARY}/
    content = content.gsub(pattern, "\\1#{to}")
  end
  SPECIAL_MAPPINGS.each do |from, transform|
    replacement = transform.call
    next unless replacement['value'] == 'LS' && replacement['params']&.first&.fetch('value', nil)
    target = replacement['params'].first['value']
    pattern = /(&kp\s+)#{Regexp.escape(from)}#{TOKEN_BOUNDARY}/
    content = content.gsub(pattern, "\\1LS(#{target})")
  end
  path.write(content)
end

TARGET_JSON_FILES.each do |file|
  next unless file.file?
  translate_json_file(file)
end

TARGET_TEXT_FILES.each do |file|
  next unless file.file?
  translate_text_file(file)
end
