#Look for duplicate names in upload file

require 'nokogiri'
require 'json'

def load_json_file(filename)
  JSON.parse(File.read(filename))
end

def xml_to_hash(xml_data:, tag:)
  a = {}
  xml_data.xpath(tag).each do |row|
    h = {}
    row.children.map do |child|
      case child.name
      when 'UniqueID'; h[:upi] = child.text.strip.split('@')[0]
      when 'FirstName'; h[:givenname] = child.text.strip
      when 'LastName'; h[:surname] = child.text.strip
      when 'Email'; h[:email] = child.text.strip
      when 'SymplecticUniqueID'; h[:uoa_id] = child.text.strip
      end
    end
    a[h[:upi]] = h
  end
  return a
end

@xml_source  = load_json_file("../Upload/hr_file_to_upload.json")

doc1 = Nokogiri::XML(File.open(@xml_source['filename']))
doc1_hash = xml_to_hash(xml_data: doc1, tag: '//Record')

doc1_hash_by_name = {}
count = 0
doc1_hash.each do |upi, attributes|
  upi_less_digits = upi[1..-1].gsub(/[0-9]+/,'')
  surname = attributes[:surname].gsub(/ /,'').gsub(/-/,'').gsub(/'/,'')
  if attributes[:givenname] == nil || attributes[:givenname] == ""
    surname_leadin = surname[1..3].downcase
  else
    surname_leadin = surname[0..2].downcase
  end
  if upi_less_digits != surname_leadin
    count += 1
    puts "#{upi} != #{surname_leadin} #{attributes[:givenname]} #{attributes[:surname]}"
  end
end
puts "#{count} mismatches"
puts "Note: Some people look to have UPI created from just their surname, even though they have a firstname"
