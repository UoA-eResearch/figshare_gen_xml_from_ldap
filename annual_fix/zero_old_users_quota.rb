#Compare an old XML upload file, with the latest one, and generate
#an upload file of those people no longer at the University.
#Set these peoples quota to 0, but don't stop them logging in.
#(Though they may not be able to authenticate with Tuakiri, having left)
#Also set these users group to unassociated (verses '', which sets it to UoA)

require 'nokogiri'
require_relative '../rlib/init.rb'
#require_relative '../rlib/get_user_attributes.rb'
require_relative '../rlib/gen_figshare_xml.rb'

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

@script_dir = File.dirname(__FILE__) + '/..'
init
new_filename = "#{@script_dir}/user_xml_files/figshare_hr_feed_correction_#{Time.now.strftime("%Y-%m-%d")}.xml"

@xml_source  = load_json_file("zero_conf.json")

doc1 = Nokogiri::XML(File.open(@xml_source['old_xml_filename']))
doc2 = Nokogiri::XML(File.open(@xml_source['current_xml_filename']))

doc1_hash = xml_to_hash(xml_data: doc1, tag: '//Record')
doc2_hash = xml_to_hash(xml_data: doc2, tag: '//Record')

gen_old_users_xml(filename: new_filename, old_users: doc1_hash, current_users: doc2_hash)

#automate next file to upload for python script to consume.
puts "Creating hr_file_to_upload.json for xml file: #{new_filename}"
File.open("#{@script_dir}/Upload/hr_file_to_upload.json","w") do |fd|
  fd.puts "{\n\"filename\": \"#{new_filename}\"\n}"
end
puts
puts "Now run Upload/upload"