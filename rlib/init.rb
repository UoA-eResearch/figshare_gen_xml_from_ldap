require 'net/ldap'
require 'json'

# LDAP_SERVER = "ldap.uoa.auckland.ac.nz"  #VIP for LDAP, which is repeatedly hitting a dead server.
LDAP_SERVER = 'uoaadsp01.uoa.auckland.ac.nz' # Override VIP, and go to just one server. Bad, but it is working.

def load_json_file(filename)
  JSON.parse(File.read(filename))
end

# Init reads the Json configuration files, setting @course_codes_to_faculty and @academic_department_code_to_faculty
# Opens a connection to the LDAP server, setting @ldap for other methods to use.
def init
  @auth = load_json_file("#{@script_dir}/conf/auth.json")
  @course_codes_to_faculty = load_json_file("#{@script_dir}/conf/course_codes_to_faculty.json")
  @academic_department_code_to_faculty = load_json_file("#{@script_dir}/conf/academic_department_code_to_faculty.json")
  @override_group  = load_json_file("#{@script_dir}/conf/override_group.json")
  @override_quota  = load_json_file("#{@script_dir}/conf/override_quota.json")
  @default_quota = 1024 * 1024 * 1024 * 10

  @ldap = Net::LDAP.new host: LDAP_SERVER, # your LDAP host name or IP goes here,
                        # port: '389', # unencrypted LDAP host port,
                        port: '636', # TLS port
                        encryption: :simple_tls,
                        base: 'DC=UoA,DC=auckland,DC=ac,DC=nz', # the base of your AD tree goes here,
                        auth: {
                          method: :simple,
                          username: @auth['username'], # a user w/sufficient privileges to read from AD goes here,
                          password: @auth['password']  # the user's password goes here
                        }
end
