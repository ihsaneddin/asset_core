module AssetCore
  module Grape
    module Helpers
      module Authorize

        def self.included(base)
          base.include Plugins::Grape::Concerns::Authorize
          base.helpers HelperMethods
          base.after_validation do
            authorize_route!
          end
        end

        module HelperMethods

          def authorize!(*args)
            if self.class.api_config.authorize.is_a?(Proc)
              instance_exec(*args ,&self.class.api_config.authorize )
            else
              current_ability.authorize!(*args)
            end
          end

          def defined_permissions
            current_user ? current_user.pos_permissions : nil
          end

          def current_ability
            ability_class = if self.class.respond_to?(:ability_class)
              self.class.ability_class
            else
              AssetCore.config.grape_api.abilitiy_class_constant
            end
            ability_class.new(current_user, self)
          end

          def skip_authorization!
            skip_authentication! || route_setting(:skip_authorization)
          end

        end

      end

    end
  end
end