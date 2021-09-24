require 'figshare_api_v2'

# Fetch the Figshare user record, using the UoA identity
# @param upi [String] UoA identity
# @yield [Hash] Figshare user record
def user_record_from_upi(figshare:, upi:, &block)
  figshare.institutions.accounts( institution_user_id: "#{upi}@auckland.ac.nz") do |a|
    figshare.other.private_account_info(impersonate: a['id'], &block)
  end
end

# Set the user record's current quota in figshare, so we can check if we need to force an update
# This is not viable at scale. A test showed that ~15,000 users queries took a little over 10 hours.
# @param users [Hash] user records, we have fetched from LDAP (the AD)
def set_figshare_quota(users:)
  figshare = Figshare::Init.new(figshare_user: 'figshare_admin', conf_dir: "#{__dir__}/../conf" )
  users.each do |upi, attributes|
    user_record_from_upi(figshare: figshare, upi: upi) do |u|
      attributes[:quota] = u['quota']
    end
  end
end

# Set the quota value in the override table to be the maximum of
# the current quota and what is in the override_quota file
# @param users [Hash] UPI indexed, quota records
def update_quota_override(users:)
  figshare = Figshare::Init.new(figshare_user: 'figshare_admin', conf_dir: "#{__dir__}/../conf" )
  users.each do |upi, quota|
    user_record_from_upi(figshare: figshare, upi: upi) do |u|
      # don't change, if they already have more quota than the override.
      users[upi] = u['quota'] >= quota ? nil : u['quota']
    end
  end
end
