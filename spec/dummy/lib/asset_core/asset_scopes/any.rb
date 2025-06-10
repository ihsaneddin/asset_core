module AssetCore
  module AssetScopes
    module Any

      extend ::AssetCore::AssetScopes::Core

      def self.scope_options
        {
          record: {
            relationships: {

            },
            callbacks: {},
            functions: {},
            entry_callbacks: {},
          },
          entry: {
            functions: {

            },
            relationships: {},
            callbacks: {},
          },
          proxy: {
            functions: {

            }
          }
        }
      end

    end
  end
end