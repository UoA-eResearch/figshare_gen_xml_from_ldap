require 'json'

def load_json_file(filename)
  JSON.parse(File.read(filename))
end

#Init reads the Json configuration files, setting @course_codes_to_faculty and @academic_department_code_to_faculty
#Opens a connection to the LDAP server, setting @ldap for other methods to use.
def init
  @auth = load_json_file("#{File.dirname(__FILE__)}/../conf/auth.json")
  @course_codes_to_faculty = load_json_file("#{File.dirname(__FILE__)}/../conf/course_codes_to_faculty.json")
  @academic_department_code_to_faculty  = load_json_file("#{File.dirname(__FILE__)}/../conf/academic_department_code_to_faculty.json")

  @ldap = Net::LDAP.new  :host => "uoa.auckland.ac.nz", # your LDAP host name or IP goes here,
                        :port => "389", # your LDAP host port goes here,
                        #:encryption => :simple_tls,
                        :base => "DC=UoA,DC=auckland,DC=ac,DC=nz", # the base of your AD tree goes here,
                        :auth => {
                          :method => :simple,
                          :username => @auth['username'], # a user w/sufficient privileges to read from AD goes here,
                          :password => @auth['password']  # the user's password goes here
                        }
end

