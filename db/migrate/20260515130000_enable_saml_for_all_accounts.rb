class EnableSamlForAllAccounts < ActiveRecord::Migration[7.1]
  def up
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config&.value.present?
      feature = config.value.find { |f| f['name'] == 'saml' }
      if feature.present?
        feature['enabled'] = true
        config.update!(value: config.value)
        GlobalConfig.clear_cache
      end
    end

    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('saml') }
    end
  end
end
