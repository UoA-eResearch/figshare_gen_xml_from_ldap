#gen_user_xml returns a single users XML record for the Figshare HR feed
#  @param upi [String] UoA login name, hence also the Tuakiri identity
#  @param givenname [String] First name(s)
#  @param surname [String] Surname
#  @param uoa_id [String] UoA staff or student ID number for matching with Symplectic Elements
#  @param email [String] email address
#  @return [String] Single users XML record for Figshare HR feed
def gen_user_xml(upi:, givenname:, surname:, uoa_id:, email:, primary_group:)
  return <<-EOT
  <Record>
     <UniqueID>#{upi}@auckland.ac.nz</UniqueID>
     <FirstName>#{givenname}</FirstName>
     <LastName>#{surname}</LastName>
     <Email>#{email}</Email>
     <IsActive>y</IsActive>
     <UserQuota>10737418240</UserQuota>
     <UserAssociationCriteria>#{primary_group}</UserAssociationCriteria>
     <SymplecticUniqueID>#{uoa_id}</SymplecticUniqueID>
  </Record>
EOT
end

#gen_xml generates a Figshare HR xml feed file from a hash of all users in the feed.
#  @param users [Hash] User records of form {:upi=>"aaaa001", :surname=>"Aaa Home Test", :givenname=>"Aaa", :email=>"", :uoa_id=>"4642721", :primary_group => ''}
#  @param filename [String] File name to write Figshare HR feed to.
def gen_xml(users:, filename: nil)
  fd = filename != nil ? File.open(filename,'w+') : $stdout #default to STDOUT, though the output will be ~150,000 lines long.
  fd.puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  fd.puts "<HRFeed>"
  users.each do |upi, attributes| #Enumerate through the user records.
    fd.puts gen_user_xml(attributes) #attributes passed as a Ruby hash, rather than individually.
  end
  fd.puts "</HRFeed>"
end
