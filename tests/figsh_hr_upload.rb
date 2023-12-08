#!/usr/local/bin/ruby

require 'figshare_api_v2'

# Chdir needed with Atom, which stays in the project dir, not the script's dir.
Dir.chdir(__dir__)

CONF_DIR = 'conf'
KEY_FILE = 'test_figsh_hr_key.json'
CONF_FILE = 'test_figsh_site_params.json'
HR_FILE = '../Upload/test_hr_file_to_upload.json'

xml_file_name = JSON.parse(File.read(HR_FILE))
Dir.chdir(__dir__) # Needed with Atom, which stays in the project dir, not the script's dir.

# Upload HR XML file to the test instance of Figshare auckland.figsh.com
@figshare = Figshare::Init.new( figshare_user: 'hr_figshare_token',
                                key_file: KEY_FILE,
                                conf_file: CONF_FILE,
                                conf_dir: CONF_DIR
                              )

@figshare.institutions.hr_upload(hr_xml_filename: xml_file_name['filename'] ) do |output|
  puts output
end
