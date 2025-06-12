module AssetCore
  module AssetScopes
    module Depreciated

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :depreciation do
        attributes([
          iniital_value: {
            type: :decimal,
          },
          start_date: {
            type: :date,
            validates: {
              timeliness: { type: :date }
            },
            allow_blank: true
          },
          residual_value: {
            type: :decimal,
            default: 0,
            validates: {
              numericality: { greater_than_or_equal_to: 0 }
            }
          },
          expected_lifespan: {
            type: :decimal,
            default: 0,
            validates: {
              numericality: { greater_than: 0 }
            }
          },
          expected_lifespan_unit: {
            type: :string,
            default: "year",
            validates: {
              inclusion: { in: %w[year month day] }
            }
          },
          depreciation_method: {
            type: :string,
            default: "",
            validates: {
              inclusion: { in: :depreciation_method_names }
            }
          },
          depreciation_rate: {
            type: :decimal,
            default: 0,
            validates: {
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
            }
          }
        ])
        functions.setup(
          **{
            depreciation_method_names: proc {
              if record
                record.available_depreciation_methods
              else
                []
              end
            }
          }
        )
        callbacks.setup(
          **{
            before_validation: proc {

            }
          }
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :depreciated do
        proxy "depreciation"
        entry_scopes([:depreciation])
        relationships.setup(
          **{
            depreciation_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            depreciation_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
          }
        )
        callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
        entry_callbacks.setup(
          **{
            before_validation: nil,
            validate: proc { |entry|
              if entries.by_entry_scopes("depreciation").where.not(id: entry.id).exists?
                entry.errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: nil
          }
        )
        functions.setup(
          **{
            available_depreciation_methods: proc {
              ::AssetCore::AssetDepreciationMethods.calculate_methods.keys.map(&:to_s)
            },
            initial_value: proc {
              depreciation_entry&.initial_value || 0
            },
            initial_value_currency: proc {
              asset.asset_config.defaults.currency
            },
            depreciation_start_date: proc {
              depreciation_entry&.start_date
            },
            residual_value: proc {
              depreciation_entry.try(:residual_value)
            },
            expected_lifespan: proc {
              depreciation_entry.try(:expected_lifespan)
            },
            expected_lifespan_unit: proc {
              depreciation_entry.try(:expected_lifespan_unit)
            },
            expected_lifespan_time: proc {
              expected_lifespan.try(expected_lifespan_unit)
            },
            depreciation_method: proc {
              depreciation_entry.try(:depreciation_method)
            },
            depreciation_rate: proc {
              depreciation_entry.try(:depreciation_rate)
            },
            depreciation_schedule: -> (date= Date.today, period= nil) {
              if depreciation_entry
                calculator_class = asset.asset_config.depreciation_calculator_class.constantize
                if calculator_class != ::AssetCore.config.asset_depreciation_methods::Calculator
                  unless calculator_class < ::AssetCore.config.asset_depreciation_methods::Calculator
                    raise "Invalid depreciation calculator class"
                  end
                end
                depreciation_method = depreciation_entry.depreciation_method
                calculator_class.new(
                  start_date: depreciation_start_date,
                  lifespan: expected_lifespan,
                  lifespan_unit: expected_lifespan_unit,
                  residual_value: residual_value,
                  initial_value: initial_value,
                  current_date: date,
                  rate: depreciation_rate,
                  method_name: depreciation_method
                ).calculate(period: period)
              else
                []
              end
            } ,
            accrued_depreciation: -> (date = Date.today) { depreciation_schedule(date).sum { |entry| entry[:value] }  },
            net_book_value: -> (date = Date.today) { initial_value - accrued_depreciation(date) },
            fully_depreciated?: proc { |date|
              net_book_value(date).zero?
            }
          }
        )
      end

      def self.scope_options
        {
          record: {
            relationships: {
              depreciation_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
              depreciation_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            },
            callbacks: { before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil },
            functions: {
              initial_value: proc {
                acquisition_value || depreciation_entry&.initial_value || 0
              },
              initial_value_currency: proc {
                acquisition_value_currency || depreciation_entry.try(:initial_value_currency)
              },
              start_date: proc {
                acquisition_date || depreciation_entry.try(:start_date)
              },
              residual_value: proc {
                depreciation_entry.try(:residual_value)
              },
              expected_lifespan: proc {
                depreciation_entry.try(:expected_lifespan)
              },
              expected_lifespan_unit: proc {
                depreciation_entry.try(:expected_lifespan_unit)
              },
              expected_lifespan_time: proc {
                expected_lifespan.try(expected_lifespan_unit)
              },
              depreciation_method: proc {
                depreciation_entry.try(:depreciation_method)
              },
              depreciation_rate: proc {
                depreciation_entry.try(:rate)
              },
              depreciation_schedule: -> (date= Date.today, period= nil) { [] } ,
              accrued_depreciation: -> (date = Date.today) { depreciation_schedule(date).sum { |entry| entry[:value] }  },
              net_book_value: -> (date = Date.today) { initial_value - accrued_depreciation(date) },
              fully_depreciated?: proc { |date|
                net_book_value(date).zero?
              }
            },
            entry_callbacks: {
              before_validation: nil,
              validate: proc { |entry|
                if entries.by_entry_scopes("depreciation").where.not(id: entry.id).exists?
                  entry.errors.add(:type, :invalid)
                end
              },
              after_validation: nil,
              before_save: nil,
              after_save: nil
            }
          },
          entry: {
            relationships: {},
            callbacks: { before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil },
            functions: {
              initial_value: proc {
                data.try(:initial_value)
              },
              initial_value_currency: proc {
                data.try(:currency)
              },
              start_date: proc {
                data.try(:start_date) || record.created_at
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
              }
            }
          },
          proxy: {
            functions: {
              initial_value: proc {
                record.initial_value
              },
              initial_value_currency: proc {
                record.try(:initial_value_currency)
              },
              start_date: proc {
                record.try(:initial_date) || record.created_at
              },
              residual_value: proc {
                record.try(:residual_value) || 0
              },
              expected_lifespan: proc {
                record.try(:expected_lifespan) || 0
              },
              expected_lifespan_unit: proc {
                record.try(:expected_lifespan_unit)
              },
              expected_lifespan_time: proc {
                record.try(:expected_lifespan_time)
              },
              depreciation_method: proc {
                record.try(:depreciation_method)
              },
              depreciation_rate: proc {
                record..try(:depreciation_rate)
              },
              depreciation_schedule: proc { |date= Date.today, period= nil|
                record.try(:depreciation_schedule, date, period)
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
        }
      end

    end
  end
end