module AssetCore
  module AssetScopes
    module Entry
      module Purchase

        extend ::AssetCore::AssetScopes::Entry

        def self.model_options
          opts = super

          opts[:before_approve] = proc {
            if asset_ownership_states_attributes.blank?
              self.asset_ownership_states_attributes = [
                { record: record, index_name: "owned" }
              ]
            end
          }

          opts
        end

      end
    end
  end
end