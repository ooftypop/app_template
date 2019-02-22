class ApplicationUploader
  require 'csv'

  # Requires Roo gem to be installed
  # def self.open_spreadsheet(file)
  #   case File.extname(file.original_filename)
  #   when ".csv" then Roo::CSV.new(file.path, csv_options: { encoding: 'windows-1251:utf-8' })
  #   when ".xls" then Roo::Excel.new(file.path)
  #   when ".xlsx" then Roo::Excelx.new(file.path)
  #   else raise "Unknown file type: #{file.original_filename}"
  #   end
  # end

  def self.format_headers(headers)
    return headers.map {|header| header.strip.downcase }
  end
end
