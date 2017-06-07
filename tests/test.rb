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
  p @academic_department_code_to_faculty[department]
  puts
end

def test_course_codes_to_faculty(course_code)
  puts "Map the course code #{course_code} to its faculty"
  p @course_codes_to_faculty[course_code]
  puts
end

def test_phd_download(ldap:)
  puts "PhD download"
  users_groups = {}
  get_phd_groups(ldap: @ldap, users_groups: users_groups)
  p users_groups
  puts
end

def test_staff_download(ldap:)
  puts "Staff download"
  users_groups = {}
  get_staff_groups(ldap: @ldap, users_groups: users_groups)
  p users_groups
  puts
end

init
test_get_user_attributes(ldap: @ldap, upi: 'aaaa001')
test_academic_department_code_to_faculty('CAIFACSERV')
test_course_codes_to_faculty('COMPSCI')
#test_phd_download(ldap: @ldap)
test_staff_download(ldap: @ldap)
