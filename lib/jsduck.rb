$:.unshift File.dirname(__FILE__) # For running the actual JsDuck app

require 'jsduck/lexer'
require 'jsduck/parser'
require 'jsduck/doc_parser'
require 'jsduck/merger'
require 'jsduck/tree'
require 'json'

require 'pp'

module JsDuck
  def JsDuck.parse(input)
    doc_parser = DocParser.new
    merger = Merger.new
    documentation = []
    current_class = nil

    Parser.new(input).parse.each do |docset|
      node = merger.merge(doc_parser.parse(docset[:comment]), docset[:code])
      # all methods, cfgs, ... following a class will be added to that class
      if node[:tagname] == :class
        current_class = node
        documentation << node
      elsif current_class
        current_class[ node[:tagname] ] << node
      else
        documentation << node
      end
    end

    documentation
  end

  # Given array of filenames, parses all files and returns array of
  # documented items in all of those files.
  def JsDuck.parse_files(filenames)
    docs = []
    filenames.each do |name|
      puts "Parsing #{name} ..."
      JsDuck.parse(IO.read(name)).each { |d| docs << d }
    end
    docs
  end

  def JsDuck.print_debug(docs)
    docs.each do |doc|
      puts (doc[:name] || "?") + ":"
      if doc[:tagname] == :class
        [:cfg, :property, :method, :event].each do |key|
          puts "  " + key.to_s + "s:"
          doc[key].each {|item| puts "    " + (item[:name] || "?")}
        end
      end
      puts
    end
  end

  # Given array of doc-objects, generates namespace tree that can be
  # later printed out in JSON.
  def JsDuck.print_tree(docs)
    puts "Docs.classData = " + JSON.generate( Tree.new.create(docs) ) + ";"
  end
end


if __FILE__ == $0 then
  JsDuck.print_tree( JsDuck.parse_files(ARGV) )
end

