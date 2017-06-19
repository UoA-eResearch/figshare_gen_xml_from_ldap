#gen_user_xml returns a single users XML record for the Figshare HR feed
#  @param upi [String] UoA login name, hence also the Tuakiri identity
#  @param givenname [String] First name(s)
#  @param surname [String] Surname
#  @param uoa_id [String] UoA staff or student ID number for matching with Symplectic Elements
#  @param email [String] email address
#  @param primary_group [String] Default Figshare group for this user ('' means UoA)
#  @param force_quota_update [Boolean] Quota remains unchanged for existing users, unless this is true.
#  @param quota [String|Numeric] Users new quota (but only if this is a new user, or force_quota_update is set)
#  @param active [Boolean] User is active. Defaults to true. If false, user can't login, and quota is set to current usage.
#  @return [String] Single users XML record for Figshare HR feed
def gen_user_xml(upi:, givenname:, surname:,  email:, uoa_id: nil, primary_group: '', force_quota_update: false, quota: nil, active: true)
  quota ||= @override_quota[upi] == nil ? @default_quota : @override_quota[upi] 
  return <<-EOT
  <Record>
     <UniqueID>#{upi}@auckland.ac.nz</UniqueID>
     <FirstName>#{givenname}</FirstName>
     <LastName>#{surname}</LastName>
     <Email>#{email}</Email>
     <IsActive>#{active ? 'Y' : 'N'}</IsActive>
     <UserQuota>#{quota}</UserQuota>#{force_quota_update ? "\n     <ForceQuotaUpdate>Y</ForceQuotaUpdate>" : ''}
     <UserAssociationCriteria>#{primary_group}</UserAssociationCriteria>#{uoa_id != nil ? "\n     <SymplecticUniqueID>#{uoa_id}</SymplecticUniqueID>" : '' }
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

#gen_old_users_xml generates a Figshare HR xml feed file from the differences between an old an current xml feed file.
#User in the old xml file, but not in the current one, have their quota set to 0, but remain active.
#They also have their default Figshare group set to unassociated.
#  @param old_users [Nokigiri::] Parsed XML loaded from old user XML file
#  @param current_users [Nokigiri::] Parsed XML loaded from current user XML file
#  @param filename [String] File name to write Figshare HR feed to.
def gen_old_users_xml(old_users:, current_users:, filename: nil)
  fd = filename != nil ? File.open(filename,'w+') : $stdout #default to STDOUT, though the output will be ~150,000 lines long.
  fd.puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  fd.puts "<HRFeed>"
  old_users.each do |upi, attributes| #Enumerate through the user records.
    if current_users[upi] == nil
      attributes[:primary_group] = 'unassociated'
      attributes[:quota] = 0
      attributes[:force_quota_update] = true
      fd.puts gen_user_xml(attributes) #attributes passed as a Ruby hash, rather than individually.
    end
  end
  fd.puts "</HRFeed>"
end
