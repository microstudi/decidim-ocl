# frozen_string_literal: true

class DevPreparations
  class << self
    def all
      localize_hosts
    end

    def localize_hosts
      Decidim::Organization.find_each do |org|
        old_host = org.host
        parts = old_host.split('.')
        new_host = "#{parts[..-2].join('.')}.local"

        puts "Changing '#{old_host}' to '#{new_host}'."
        org.update_attribute(:host, new_host)
      end
    end
  end
end

DevPreparations.all
