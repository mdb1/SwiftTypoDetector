#!/usr/bin/env ruby

require 'ffi/aspell'

# Initialize Aspell and dictionary
speller = FFI::Aspell::Speller.new('en_US')

# Learn new words from config file
project_path = ARGV[0]
learned_words_path = File.join(project_path, 'learned_words.txt')
learned_words = []
if File.exists?(learned_words_path)
  File.readlines(learned_words_path).each do |line|
    learned_words << line.strip
  end
end

script_directory = File.dirname(__FILE__)
swift_words_path = File.join(script_directory, 'swift_generic_words.txt')
swift_words = []
if File.exists?(swift_words_path)
  File.readlines(swift_words_path).each do |line|
    swift_words << line.strip
  end
end

def looks_like_regex_or_special_format?(line)
  special_chars = ['[', ']', '{', '}', '+', '*', '\\']
  special_chars_count = special_chars.map { |char| line.count(char) }.sum
  special_chars_count > 4  # This is arbitrary; adjust as you see fit
end

$typo_count = 0

# Search for typos in a file
def search_typos(file_path, speller, learned_words, swift_words)
  File.foreach(file_path).with_index do |line, line_num|
    # Skip URLs
    return if line.match?(/https?:\/\/[\S]+/)

    # Skip long alphanumeric strings
    return if line.match?(/[a-zA-Z0-9_]{20,}/)

    # Skip line if it looks like a regex or special format
    return if looks_like_regex_or_special_format?(line)

    # Handle sequences of uppercase letters in camelCased words
    line.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1 \2')
    
    # Split camelCased words
    line.gsub!(/([a-z\d])([A-Z])/,'\1 \2')

    words = line.gsub(/[^a-zA-Z\s’']/, ' ').split

    words.each do |word|
      next if speller.correct?(word) || learned_words.include?(word.downcase) || swift_words.include?(word.downcase)

      # Handle possessive and contractions
      root_word = word.gsub(/'s\b/, '')  # Remove 's for possessive singular
      root_word = root_word.gsub(/'\b/, '')  # Remove ' for possessive plural
      if root_word.include?("'")  # likely a contraction
        parts = root_word.split("'")
        next if parts.all? { |part| speller.correct?(part) || learned_words.include?(part.downcase) || swift_words.include?(part.downcase) }
      end
      puts "#{file_path}:\nline #{line_num + 1}: #{word}. Typo detected: \"#{word}\""
      # Increment typo count whenever you find a typo
      $typo_count += 1
    end
  end
end

unless project_path
  puts "Usage: ruby typos_checker.rb <path_to_project>"
  exit(1)
end

# Traverse the project files
Dir.glob("#{project_path}/**/*").each do |file|
  # Note: If you want to check other types of files, just change the following assertion.
  if File.file?(file) && File.extname(file) == '.swift'
    search_typos(file, speller, learned_words, swift_words)
  end
end

puts "Total typos found: #{$typo_count}"
