#!/usr/bin/env ruby
# encoding: UTF-8

require 'ffi/aspell'

# Initialize Aspell and dictionary
speller = FFI::Aspell::Speller.new('en_US')

# Learn new words from all the `learned_words.txt` files inside the path
learned_words = []
project_path = ARGV[0]
# Given your project path variable 'project_path'
Dir.glob(File.join(project_path, '**', 'learned_words.txt')) do |path|
  if File.exists?(path)
    File.readlines(path).each do |line|
      learned_words << line.strip
    end
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
  special_chars_count > 10  # This is arbitrary; adjust as you see fit
end

def contains_many_numbers?(line, threshold = 7)
  num_count = line.scan(/\d/).count
  return num_count >= threshold
end

# New global variables to keep track of unlearned words and their counts
$typo_count = 0
$unlearned_words = {}
$unlearned_words_count = Hash.new(0)

# Search for typos in a file
def search_typos(file_path, speller, learned_words, swift_words)
  File.foreach(file_path, encoding: "UTF-8").with_index do |line, line_num|
    line = line.scrub
    # Remove single-line URLs from the line
    next if line.include?("http://")
    next if line.include?("https://")

    # Remove UUIDs from the line
    line.gsub!(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/, "")

    # Skip if the line contains many numbers (probably an id)
    next if contains_many_numbers?(line)

    # Skip line if it looks like a regex or special format
    next if looks_like_regex_or_special_format?(line)

    # Handle sequences of uppercase letters in camelCased words in line
    line.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1 \2')

    # Split camelCased words in line
    line.gsub!(/([a-z\d])([A-Z])/,'\1 \2')

    # Finally, process the words in line
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
      # Update global variables for unlearned words
      $unlearned_words[word.downcase] = true
      $unlearned_words_count[word.downcase] += 1
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

puts ""
puts "============="
puts "Total typos found: #{$typo_count}"
puts "============="
puts ""

if $typo_count > 0
  # Generate unlearned_words.txt in the project root directory
  unlearned_words_path = File.join(project_path, 'unlearned_words.txt')
  File.open(unlearned_words_path, "w") do |file|
    $unlearned_words.keys.sort.each do |word|
      file.puts(word)
    end
  end

  # Generate unlearned_words_count.txt in the project root directory
  unlearned_words_count_path = File.join(project_path, 'unlearned_words_count.txt')
  File.open(unlearned_words_count_path, "w") do |file|
    $unlearned_words_count.group_by { |_, v| v }.sort.reverse.each do |count, words|
      file.puts("## #{count} Appearances")
      words.map { |word, _| word }.sort.each { |word| file.puts(word) }
    end
  end

  puts "Two files have been created in the root of your project path (#{project_path}):"
  puts "1. unlearned_words.txt - This file contains all the unique typos, sorted alphabetically."
  puts "2. unlearned_words_count.txt - This file contains the typos under their frequencies, sorted by frequency."
  puts "Remember to delete these files before pushing to the repository."
else
  # Delete the files if they exist
  [File.join(project_path, 'unlearned_words.txt'), File.join(project_path, 'unlearned_words_count.txt')].each do |file_path|
    File.delete(file_path) if File.exist?(file_path)
  end

  puts "No typos were found."
end
