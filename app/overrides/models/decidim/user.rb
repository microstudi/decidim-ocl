# frozen_string_literal: true

Decidim::User.class_eval do
  def needs_password_update?
    return false unless admin?
    return false unless Decidim.config.admin_password_strong
    return false if Decidim.config.admin_password_expiration_days == 0
    return true if password_updated_at.blank?

    password_updated_at < Decidim.config.admin_password_expiration_days.days.ago
  end
end
