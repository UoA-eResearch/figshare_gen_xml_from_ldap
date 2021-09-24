#!/usr/bin/env ruby
require 'time'
require_relative '../rlib/init.rb'
require_relative '../rlib/gen_figshare_xml.rb'
require_relative '../rlib/get_user_attributes.rb'
require_relative '../rlib/figshare_user_record.rb'

puts "#{Time.now} Started run"

@script_dir = File.dirname(__FILE__) + '/..'
init # Connect to LDAP, and read the conf files.

# Unset overide quota, if the quota is already set to the same value.
update_quota_override(users: @override_quota)

# Ensure we have the upload user in the feed
FIGSHARE_HR = {
  upi: 'figshare_hr',
  givenname: 'Hr',
  surname: 'Figshare',
  email: 'figshare@auckland.ac.nz',
  primary_group: '',
  uoa_id: ''
}

user_attributes = {} # We build up all the XML attributes for a user in this hash.
users_groups = {}    # We fetch user faculty membership, by upi, in this hash. Array of Faculty

get_phd_groups(ldap: @ldap, users_groups: users_groups)
puts "#{Time.now} users_groups after PHD query #{users_groups.length}"

get_staff_groups(ldap: @ldap, users_groups: users_groups)
puts "#{Time.now} users_groups after Staff query #{users_groups.length}"

# Override the faculty, for users in the override_group.json file.
# Has a side effect of adding in a user that isn't in the PhD or Staff LDAP groups
@override_group.each do |k, v|
  if Time.parse(v['expires']) > Time.now
    puts "Overriding groups for #{k}. Setting group to #{v['group']}"
    users_groups[k] = [ v['group']] if Time.parse(v['expires']) > Time.now
  end
end
puts "#{Time.now} users_groups after override #{users_groups.length}"

# We need to query the LDAP for each users basic details.
puts 'Getting user details from LDAP'
users_groups.each do |k, v|
  # puts "#{Time.now} user #{k}"
  user_attributes[k] = get_user_attributies(ldap: @ldap, upi: k, attributes: { 'cn' => :upi, 'sn' => :surname, 'givenname' => :givenname, 'mail' => :email, 'employeenumber' => :uoa_id } )
  # Set the user's primary figshare group to the faculty, if there is only one, or to the empty string, if there is more than one.
  # The empty string force the primary group to be at the UoA level.
  user_attributes[k][:primary_group] = (v.length == 1 ? v[0] : '')
  # user_attributes[k][:force_quota_update] = true  #Override the Figshare quota, which may have been changed through web interface.
end

# Add upload user.
puts "#{Time.now} Adding figshare user"
user_attributes[FIGSHARE_HR[:upi]] = FIGSHARE_HR

# Generate the Figshare HR feed XML file from the collected attributes.
new_filename = "#{@script_dir}/user_xml_files/figshare_hr_feed_#{Time.now.strftime('%Y-%m-%d')}.xml"

puts "#{Time.now} Generating xml file"
gen_xml(users: user_attributes, filename: new_filename)

# automate next file to upload for python script to consume.
puts "#{Time.now} Creating hr_file_to_upload.json for xml file: #{new_filename}"
File.open("#{@script_dir}/Upload/hr_file_to_upload.json", 'w') do |fd|
  fd.puts "{\n\"filename\": \"#{new_filename}\"\n}"
end

puts "#{Time.now} Finished run"
