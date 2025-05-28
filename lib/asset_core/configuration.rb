module AssetCore
  module Configuration
    autoload :Api, "asset_core/configuration/api"
    autoload :GrapeApi, "asset_core/configuration/grape_api"
    autoload :Permissions, "asset_core/configuration/permissions"
    autoload :Models, "asset_core/configuration/models"

    include Plugins::Configuration::Core

    self.api= AssetCore::Configuration::Api
    self.grape_api= AssetCore::Configuration::GrapeApi
    self.permission_class= AssetCore::Configuration::Permissions::Permission

    autoload :Sidekiq, "asset_core/configuration/sidekiq"

    mattr_accessor :sidekiq
    @@sidekiq = Sidekiq

    mattr_accessor :enabled_api
    @@enabled_api = :grape

    mattr_accessor :models
    @@models = ::AssetCore::Configuration::Models.new

    mattr_accessor :application_record_base
    @@application_record_base = "AssetCore::ApplicationRecord"

    def self.application_record_base_constant
      application_record_base.constantize
    end

    mattr_accessor :soft_delete_enabled
    @@soft_delete_enabled = true

  end
end