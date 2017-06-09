#!/usr/bin/env ruby
require_relative 'rlib/init.rb'
require_relative 'rlib/gen_figshare_xml.rb'
require_relative 'rlib/get_user_attributes.rb'

puts "Started run at #{Time.now}"

init #Connect to LDAP, and read the conf files.
user_attributes = {} #We build up all the XML attributes for a user in this hash.
users_groups = {}    #We fetch user faculty membership, by upi, in this hash.
get_phd_groups(ldap: @ldap, users_groups: users_groups)
get_staff_groups(ldap: @ldap, users_groups: users_groups)
#We need to query the LDAP for each users basic details.
users_groups.each do |k,v|
  user_attributes[k] = get_user_attributies(ldap: @ldap, upi: k, attributes: {'cn' => :upi, 'sn' => :surname, 'givenname'=>:givenname, 'mail'=>:email, 'employeenumber'=>:uoa_id} )
  #Add in the faculty, which isn't in a users basic LDAP attributes.
  user_attributes[k][:primary_group] = @override_group[k] != nil ? @override_group[k] : (v.length == 1 ? v[0] : '') 
end
#Generate the Figshare HR feed XML file from the collected attributes.
new_filename = "user_xml_files/figshare_hr_feed_#{Time.now.strftime("%Y-%m-%d")}.xml"

gen_xml(users: user_attributes, filename: new_filename)

#automate next file to upload for python script to consume.
puts "Creating file #{new_filename}"
File.open("Upload/hr_file_to_upload.json","w") do |fd|
  fd.puts "{\n\"filename\": \"../#{new_filename}\"\n}"
end

puts "Finished run at #{Time.now}"
