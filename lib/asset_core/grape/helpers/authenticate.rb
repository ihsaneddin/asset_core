module AssetCore
  module Grape
    module Helpers
      module Authenticate

        def self.included(base)
          base.helpers HelperMethods
        end

        module HelperMethods

          def authenticate!()
            super
            if @current_user
              Plugins::Errors::ApiAuthenticationError unless current_user.class.include?(AssetCore::Models::Concerns::ActsAsAssetCoreUser)
            end
            @current_user
          end

          def authenticate_admin!()
            unless skip_authentication!
              current_admin ? current_admin : reject_unauthenticated!
            end
          end

          def current_admin
            @current_admin ||= instance_exec(&api_config.authenticate_admin) if api_config.authenticate_admin.is_a?(Proc)
          end

          def current_store
            @current_store ||= instance_exec(&api_config.store) if api_config.store.is_a?(Proc)
          end

        end

      end

    end
  end
end