module AssetCore
  module AssetScopes
    module Depreciation

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
              data.try(:initial_value) || record.acquisition_entry.try(:acquisition_value)
            },
            initial_value_currency: proc {
              data.try(:currency) || record.acquisition_entry.try(:acquisition_value_currency)
            },
            start_date: proc {
              data.try(:start_date) || record.acquisition_entry.try(:acquisition_date) || record.created_at
            },
            residual_value: proc {
              data.try(:residual_value)
            },
            expected_lifespan: proc {
              data.try(:expected_lifespan)
            },
            expected_lifespan_unit: proc {
              data.try(:expected_lifespan_unit)
            },
            expected_lifespan_time: proc {
              expected_lifespan.try(expected_lifespan_unit)
            },
            depreciation_method: proc {
              data.try(:depreciation_method)
            },
            depreciation_rate: proc {
              data.try(:rate)
            },
            depreciation_schedule: -> (date= Date.today, period= nil) { [] } ,
            accrued_depreciation: -> (date = Date.today) { depreciation_schedule(date: date).sum { |entry| entry[:value] }  },
            net_book_value: -> (date = Date.today) { initial_value - accrued_depreciation(date) },
            fully_depreciated?: proc { |date|
              net_book_value(date).zero?
            }
          },
          proxy_methods: {
            initial_value: proc {
              record.depreciation_entry.try(:initial_value)
            },
            initial_value_currency: proc {
              record.depreciation_entry.try(:initial_value_currency)
            },
            start_date: proc {
              record.depreciation_entry.try(:initial_date) || record.created_at
            },
            residual_value: proc {
              record.depreciation_entry.try(:residual_value) || 0
            },
            expected_lifespan: proc {
              record.depreciation_entry.try(:expected_lifespan) || 0
            },
            expected_lifespan_unit: proc {
              record.depreciation_entry.try(:expected_lifespan_unit)
            },
            expected_lifespan_time: proc {
              record.depreciation_entry.try(:expected_lifespan_time)
            },
            depreciation_method: proc {
              record.depreciation_entry.try(:depreciation_method)
            },
            depreciation_rate: proc {
              record.depreciation_entry.try(:depreciation_rate)
            },
            depreciation_schedule: proc { |date= Date.today, period= nil|
              record.depreciation_entry.try(:depreciation_schedule, date, period)
            },
            accrued_depreciation: -> (date = Date.today) {
              depreciation.depreciation_schedule(date).sum { |entry| entry[:value] }
            },
            net_book_value: -> (date = Date.today) {
              depreciation.initial_value - depreciation.accrued_depreciation(date)
            },
            fully_depreciated?: proc {  |date|
              depreciation.net_book_value(date).zero?
            }
          }
        }
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end