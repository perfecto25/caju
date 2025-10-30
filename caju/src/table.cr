require "tallboy"


module Caju::Table
  extend self

  def print_table(json)
    puts "printing table"
  end

  class TablePrinter
    # Method to print a table from 2D array
    def self.print_table(data, headers)
    # Determine the maximum width for each column
    column_widths = (0...headers.size).map do |i|
        [headers[i].to_s.size] + data.map { |row| row[i].to_s.size }
    end
      
    # Print headers
    puts headers.each_with_index.map { |header, i| header.to_s.ljust(column_widths[i]) }.join(" | ")
    puts "-" * headers.map.with_index { |_, i| column_widths[i] + 3 }.sum
    
    # Print rows
    data.each do |row|
      puts row.each_with_index.map { |cell, i| cell.to_s.ljust(column_widths[i]) }.join(" | ")
    end
    end
  end


end # module