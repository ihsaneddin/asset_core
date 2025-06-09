module AssetCore
  module AssetScopes
    module Any

      extend ::AssetCore::AssetScopes::Core

      def self.scope_options
        {
          record_relationships: {
            has_one: [:depreciation_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
          },
          entry_callbacks: {
            before_validation: nil,
            validate: proc {
              if record.entries.by_entry_scopes("depreciation").where.not(id: id).exists?
                errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: nil
          },
          entry_methods: {
            initial_value: proc {
              record.acquisition_entry.try(:initial_value)
            },
            start_date: :created_at,
            residual_value: 0,
            expected_lifespan: 0,
            expected_lifespan_unit: "year",
            depreciation_method: "straight_line",
            rate: 0
          },
          proxy_methods: {

          }
        }
      end

    end
  end
end