module AssetCore
  module Grape
    module Presenters
      class Base < ::Grape::Entity

        root "data", "data"

        def current_user
          locals[:current_user]
        end

        def current_admin
          locals[:current_admin]
        end

        def current_store
          locals[:current_store]
        end

        def locals
          options[:locals] || {}
        end

      end
    end
  end
end