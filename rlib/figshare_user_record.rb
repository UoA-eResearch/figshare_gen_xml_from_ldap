require 'figshare_api_v2'

# Preload current Figshare user records, so we can check quota, and existance of users
# This is much faster than making > 14,000 individual REST calls. It still takes about 5m.
# Each Figshare account record is of the form:
# {  "id":,                       # Figshare's account table index
#    "user_id":                  # Figshare user table index
#    "first_name":, "last_name":,
#    "email":"                   # UoA email address, so either @auckland or @aucklanduni
#    "active":                   # User's account is active = 1 or inactive = 0
#                                  We set the quota to 0, rather than setting inactive
#    "institution_id":           # Constant for all users in the institute
#    "institution_user_id":      # upi@auckland.ac.nz,
#    "symplectic_user_id":       # UoA ID number,
#    "quota":                    # We default to 10,737,418,240, (10G) or 0 for non-current users
#    "used_quota":
# }
# Sets @active_users and @inactive_users, both indexed by Figshares account ID
# Also sets user indexes @email and @institute_id (i.e. indexed by the upi@auckland.ac.nz)
#
# @param active [Integer] Get active (default), inactive (0) or all active: nil?)  users
def institute_accounts(active: 1)
  # Globals.
  @active_users = {}
  @inactive_users = {}   # We do have a few, from the early days, but then we just set the quota to 0.
  @email = {}
  @institute_id = {}     # By UPI@auckland

  @figshare.institutions.accounts(is_active: active) do |a|
    @email[a['email']] = a
    @institute_id[a['institution_user_id']] = a
    if a['active'] == 1
      @active_users[a['id']] = a
    else
      @inactive_users[a['id']] = a
    end
  end
end

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
