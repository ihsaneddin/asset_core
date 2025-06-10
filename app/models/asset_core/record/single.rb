module AssetCore
  class Record::Single < ::AssetCore::Record

    class Attributes < ::AssetCore::Record::Attributes

      attribute :name, :string

    end

    define_asset_type :single, scopes: [ :acquisition, :purchase, :donation, :depreciation, :release ] do
      purchase do
        entry_callbacks do
          after_save do |entry|
            if entry.state == "approved" && entry.saved_change_to_state?
              if asset
                asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                asset_state.save
              end
            end
          end
        end
      end
      depreciation do
        functions do
          depreciation_schedule do |date= Date.today, period=nil|
            if depreciation_entry
              method_class = depreciation_entry.method_class.safe_constantize
              raise "Unknown depreciation method: #{depreciation_method}" unless method_class

              method_class.new(
                start_date: start_date,
                lifespan: expected_lifespan,
                lifespan_unit: expected_lifespan_unit,
                residual_value: residual_value,
                initial_value: initial_value,
                current_date: date,
                rate: depreciation_rate
              ).calculate(period: period)
            else
              []
            end
          end
          accrued_depreciation do |date= Date.today|
            depreciation_schedule(date).sum { |entry| entry[:value] }
          end
          net_book_value do |date=Date.today|
            initial_value - accrued_depreciation(date)
          end
        end
      end
    end

  end
end
