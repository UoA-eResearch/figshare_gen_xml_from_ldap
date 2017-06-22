#!/usr/bin/env ruby
require_relative '../rlib/init.rb'
require_relative '../rlib/get_user_attributes.rb'
require_relative '../rlib/gen_figshare_xml.rb'

def test_get_user_attributes(ldap:, upi:)
 ua = get_user_attributies(ldap: ldap, upi: upi, attributes: {'cn' => :upi, 'sn' => :surname, 'givenname'=>:givenname, 'mail'=>:email, 'employeenumber'=>:uoa_id} )
 puts "Generate Ruby hash from an LDAP lookup of our dummy user"
 p ua
 puts
 puts "Generate Figshare HR XML record for this dummy user"
 ua[:primary_group] = 'dummy'
 print gen_user_xml(ua)
 puts
end

def test_academic_department_code_to_faculty(department)
  puts "Map department #{department} to its faculty"
  group_def = @academic_department_code_to_faculty[department]
  p group_def == nil ? 'nil' : group_def["faculty"]
  puts
end

def test_course_codes_to_faculty(course_code)
  puts "Map the course code #{course_code} to its faculty"
  group_def = @course_codes_to_faculty[course_code]
  p group_def == nil ? 'nil' : group_def["faculty"]
  puts
end

def test_phd_download(ldap:)
  puts "PhD download"
  users_groups = {}
  get_phd_groups(ldap: @ldap, users_groups: users_groups)
  users_groups.each do |k,v|
    puts "#{k} => #{v}"
  end
  puts
end

def test_staff_download(ldap:)
  puts "Staff download"
  users_groups = {}
  get_staff_groups(ldap: @ldap, users_groups: users_groups)
  users_groups.each do |k,v|
    puts "#{k} => #{v}"
  end
  puts
end

def testing_get_groups(ldap:, users_groups:, staff: true)
  if staff
    filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*.staff.uos")
    treebase = "dc=UoA,dc=auckland,dc=ac,dc=nz"
  else
    filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*phd*.now")
    treebase = "OU=now,OU=Groups,dc=UoA,dc=auckland,dc=ac,dc=nz"
  end

  ldap.search( :base => treebase, :filter => filter, :attributes => ['member'] ) do |entry|
=begin
#Raw dump, to see what is in the LDAP.
    puts "DN: #{entry.dn}"
    entry.each do |attribute, values|
      puts "   #{attribute}:"
      values.each do |value|
        puts "      --->#{value}"
      end
    end
=end
begin
    #eg CN=SCIFAC.staff.uos,OU=uos,OU=Groups,DC=UoA,DC=auckland,DC=ac,DC=nz
    group = entry.dn.split(',')[0].split('=')[1].split('.')[0]
    entry.each do |attribute, values|
      if attribute =~ /^member/ #Getting empty member attributes, and new attribute: member;range=0-1499 for SCIFAC and MEDFAC.
        values.each do |value|
          member = value.split('=')[1].split(',')[0]
          users_groups[member] ||= []    #If this is the users first group, then create an Array
          #Add this group to this users group Array, only if group not already in Array
          group_def =  staff ? @academic_department_code_to_faculty[group] : @course_codes_to_faculty[group]
          if (group_def != nil && faculty = group_def["faculty"]) != nil && users_groups[member].include?(faculty) == false
            users_groups[member] << group_def["faculty"]
          end
        end
      end
    end  
end
  end
end

@script_dir = File.dirname(__FILE__) + '/..'
puts @script_dir

init
#test_get_user_attributes(ldap: @ldap, upi: 'aaaa001')
#test_academic_department_code_to_faculty('CAIFACSERV')
#test_course_codes_to_faculty('COMPSCI')
#test_phd_download(ldap: @ldap)
#test_staff_download(ldap: @ldap)

users = {}
testing_get_groups(ldap: @ldap, users_groups: users)
#testing_get_groups(ldap: @ldap, users_groups: users, staff: false)
#puts users.length
users.each { |u,v| puts "#{u} => #{v}"}
