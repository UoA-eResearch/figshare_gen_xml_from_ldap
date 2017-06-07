require 'net/ldap'

#get_user_attributies reads from the UoA LDAP, and retrieves a user's record
#  @param ldap [NET::LDAP] LDAP file descriptor open to to UoA LDAP
#  @param attributes [Hash] pairs of <LDAP attribute> => <Output attribute name in Hash>
#  @return [Hash] Single users LDAP record, with just the attributes requested
def get_user_attributies(ldap:, upi:, attributes:)
  response={}
  filter = Net::LDAP::Filter.eq( "objectCategory","user" ) & Net::LDAP::Filter.eq("cn","#{upi}*")
  treebase = 'OU=People,DC=UoA,DC=auckland,DC=ac,DC=nz' #restrict output, otherwise we get a third user record.
  ldap.search( :base => treebase, :filter => filter ) do |entry|
    attributes.each do |attribute,value|
      response[value] = entry[attribute][0].to_s.strip
    end
    return response #Only want the first entry. Not sure why there are two identical records per person
  end
end

#get_phd_groups retrieves all the PhD students (in 898 courses) with their faculty affiliation
#  @param ldap [NET::LDAP] LDAP file descriptor open to to UoA LDAP
#  @users_groups [Hash] This hash gets filled in with <upi> => [<faculty>, ...]
def get_phd_groups(ldap:, users_groups: )
  filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*898*")
  treebase = "dc=UoA,dc=auckland,dc=ac,dc=nz"

  ldap.search( :base => treebase, :filter => filter ) do |entry|
    group_pieces = entry.dn.split('=')[1].split(',')[0].split('.')
    if group_pieces.length > 2 #Want only the courses, not stray groups with 898 in their names.
      group = group_pieces[0]
      entry['member'].each do |value|
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
def get_staff_groups(ldap:, users_groups: )
  filter = Net::LDAP::Filter.eq( "objectCategory","group" ) & Net::LDAP::Filter.eq("cn","*.staff.uos")
  treebase = "dc=UoA,dc=auckland,dc=ac,dc=nz"

  ldap.search( :base => treebase, :filter => filter ) do |entry|
    group = entry.dn.split('=')[1].split(',')[0].split('.')[0]
    entry['member'].each do |value|
      member = value.split('=')[1].split(',')[0]
      users_groups[member] ||= []    #If this is the users first group, then create an Array
      #Add this group to this users group Array, only if group not already in Array
      if (faculty = @academic_department_code_to_faculty[group]) != nil && users_groups[member].include?(faculty) == false
        users_groups[member] << faculty 
      end
    end
  end 
end








