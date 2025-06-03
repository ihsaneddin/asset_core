module AssetCore
  module AssetScopes
    module Entry
      module Acquisition

        extend ::AssetCore::AssetScopes::Entry

        def self.model_options
          opts = super

          opts[:guard_approve] = proc {
            !record.entries.approved.by_entry_scopes("acquisition").where.not(id: id).exists?
          }

          opts[:validations] = proc {
            if record.entries.by_entry_scopes("acquisition").where.not(id: id).exists?
              errors.add(:invalid, :record)
            end
          }
          opts
        end

        def self.proxy_options
          opts = super(scope_name)

          opts[:functions] = ::Plugins::Models::Config.new({
            initial_value: proc {
              acquisition_entries_collection.first.initial_value
            }
          })

          opts
        end

      end
    end
  end
end