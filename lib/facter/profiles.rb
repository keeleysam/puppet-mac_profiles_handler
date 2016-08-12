require 'puppet/util/plist'
require 'time'

Facter.add(:profiles) do
  confine kernel: 'Darwin'
  setcode do
    profiles = {}

    if Facter.value(:os)['release']['major'].to_i >= 12

      output = Facter::Util::Resolution.exec('/usr/sbin/system_profiler SPConfigurationProfileDataType -xml')

      for item in Puppet::Util::Plist.parse_plist(output)[0]['_items'][0]['_items']
        profiles[item['spconfigprofile_profile_identifier']] = {
          'display_name' => item['_name'],
          'description' => item['spconfigprofile_description'],
          'verification_state' => item['spconfigprofile_verification_state'],
          'uuid' => item['spconfigprofile_profile_uuid'],
          'organization' => item['spconfigprofile_organization'],
          'install_date' => DateTime.parse(item['spconfigprofile_install_date'].scan(/\(([^\)]+)\)/).last.first).to_s,
          'payload' => []
        }

        for pl in item['_items']
          profiles[item['spconfigprofile_profile_identifier']]['payload'] << {
            'name' => pl['_name'],
            'display_name' => pl['spconfigprofile_payload_display_name'],
            'identifier' => pl['spconfigprofile_payload_identifier'],
            'uuid' => pl['spconfigprofile_payload_uuid'],
            # commented out because this is returned in old ASCII plist format
            # which cfpropertylist cannot handle, so the data is useless.
            # 'data' => pl['spconfigprofile_payload_data'],
          }
        end
      end
    end

    profiles
  end
end
