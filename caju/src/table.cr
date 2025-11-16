require "tallboy"


module Caju::Table
  extend self

  def print_table(column_data , row_data )
    puts "printing table #{column_data} , #{row_data}"
    
    if column_data.nil?
      puts "NILLLL"
    end

    begin
      table = Tallboy.table do
        # unless column_data.nil?
        #   cdata = column_data 
        #   column_data.not_nil!.each do |c|
        #     add c
        #   end

        #   columns do
        #     cdata.each do |c|
        #       add c
        #     end
        #   end
        # end

        header
          
        if row_data
          row_data.each |r| do
            rows r  
          end
        end
      end # table

      puts table.render(:markdown) 

    rescue error
      puts error.colorize(:red)
      error.inspect_with_backtrace(STDOUT)
      exit 1
    end # begin
  end # def


end # module