#get_user_attributies reads from the UoA LDAP, and retrieves a user's record
#  @param ldap [NET::LDAP] LDAP file descriptor open to to UoA LDAP
#  @param attributes [Hash] pairs of <LDAP attribute> => <Output attribute name in Hash>
#  @return [Hash] Single users LDAP record, with just the attributes requested
def get_user_attributies(ldap:, upi:, attributes:)
  response={}
  filter = Net::LDAP::Filter.eq( "objectCategory","user" ) & Net::LDAP::Filter.eq("cn","#{upi}*")
  treebase = 'OU=People,DC=UoA,DC=auckland,DC=ac,DC=nz' #restrict output, otherwise we get a third user record.
  ldap.search( :base => treebase, :filter => filter, :attributes => ['cn','sn','givenname','mail','employeenumber'] ) do |entry|
    attributes.each do |attribute,value|
      if value == :email #Horrible hack, as we are still getting the odd user_gal email address.
        response[value] = entry[attribute][0].to_s.strip.gsub(/_gal@/, '@')
      else
        response[value] = entry[attribute][0].to_s.strip
      end
    end
    return response #Only want the first entry. Not sure why there are two identical records per person
  end
  return response #Catch all if ldap search fails to get a result.
end

#get_phd_groups retrieves all the PhD students (in 898 courses) with their faculty affiliation
#  @param ldap [NET::LDAP] LDAP file descriptor open to to UoA LDAP
#  @users_groups [Hash] This hash gets filled in with <upi> => [<faculty>, ...]
def get_phd_groups(ldap:, users_groups: )
  #Get all the PhD's, which will include last years ones too, and these will have no paper.
  filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*phd*.now")
  treebase = "OU=now,OU=Groups,dc=UoA,dc=auckland,dc=ac,dc=nz"

  ldap.search( :base => treebase, :filter => filter, :attributes => ['member'] ) do |entry|
    group = entry.dn.split(',')[0].split('=')[1].split('.')[0]
    entry.each do |attribute, values|
      if attribute =~ /^member/ #Getting empty member attributes, and new attribute: member;range=0-xxxx, as this group is large.
        values.each do |value|
          member = value.split('=')[1].split(',')[0]
          users_groups[member] ||= []    #If this is the users first group, then create an Array
        end
      end
    end  
  end 

  #Get the PhD's again, this time by level 8 paper, so we can determine the Faculty.
  filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*.8*.now")
  treebase = "OU=now,OU=Groups,dc=UoA,dc=auckland,dc=ac,dc=nz"

  ldap.search( :base => treebase, :filter => filter, :attributes => ['member'] ) do |entry|
    group_pieces = entry.dn.split('=')[1].split(',')[0].split('.')
    if group_pieces.length > 2 #Want only the courses, not stray groups with 898 in their names.
      group = group_pieces[0]
      entry['member'].each do |value| #PhD groups small enough, so no member;range attributes.
        member = value.split('=')[1].split(',')[0]
        users_groups[member] ||= []    #If this is the users first group, then create an Array
        #Add this group to this users group Array, only if group not already in Array
        if (faculty = @course_codes_to_faculty[group]) != nil && users_groups[member].include?(faculty) == false
          users_groups[member] << faculty 
        end
      end
    end
  end 
end

#get_staff_groups retrieves all staff with their faculty affiliation
#  @param ldap [NET::LDAP] LDAP file descriptor open to to UoA LDAP
#  @users_groups [Hash] This hash gets filled in with <upi> => [<faculty>, ...]
def get_staff_groups(ldap:, users_groups:)
  filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*.staff.uos")
  treebase = "dc=UoA,dc=auckland,dc=ac,dc=nz"

  ldap.search( :base => treebase, :filter => filter, :attributes => ['member'] ) do |entry|
    #eg CN=SCIFAC.staff.uos,OU=uos,OU=Groups,DC=UoA,DC=auckland,DC=ac,DC=nz
    group = entry.dn.split(',')[0].split('=')[1].split('.')[0]
    entry.each do |attribute, values|
      if attribute =~ /^member/ #Getting empty member attributes, and new attribute: member;range=0-XXXX for SCIFAC and MEDFAC.
        values.each do |value|
          member = value.split('=')[1].split(',')[0]
          users_groups[member] ||= []    #If this is the users first group, then create an Array
          #Add this group to this users group Array, only if group not already in Array
          if (faculty = @academic_department_code_to_faculty[group]) != nil && users_groups[member].include?(faculty) == false
            users_groups[member] << faculty 
          end
        end
      end
    end  
  end 
end








