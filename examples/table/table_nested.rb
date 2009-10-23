# encoding: utf-8
#
# Shows off nested tables: embedding a Table in a Table
#
require "#{File.dirname(__FILE__)}/../example_helper.rb"

Prawn::Document.generate "table_nested.pdf" do |pdf|
  subtable = Prawn::Table.new([["subtable 1 left", "subtable 1 right"],
                               ["subtable 2 left", "subtable 2 right"]], pdf,
                              :headers => ["<-", "->"])
 
  pdf.table([["row 1"], 
             ["row 2"], 
             [subtable], 
             ["last row"]], :headers => ["head"])
end
