require "asset_core/version"
require "asset_core/engine"
require 'alba'
require 'plugins'
require 'grape'
require 'grape-entity'
require 'validates_timeliness'
require 'aasm'
require 'hashdiff'
require 'closure_tree'

module AssetCore

  autoload :Configuration, "asset_core/configuration"
  autoload :Controllers, "asset_core/controllers"
  autoload :Models, "asset_core/models"
  autoload :AssetScopes, "asset_core/asset_scopes"
  autoload :Grape, "asset_core/grape"
  autoload :Errors, "asset_core/errors"

  mattr_accessor :configuration
  @@configuration = Configuration

  def self.config
    @@configuration
  end

  def self.setup &block
    config.setup &block
  end

end

require "asset_core/railtie"