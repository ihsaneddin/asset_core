module AssetCore
  class Entry::Depreciation < AssetCore::Entry

    class Attributes < AssetCore::Attributes
      attribute :start_date, :date
      attribute :expected_lifespan, :integer, default: 1
      attribute :expected_lifespan_unit, :string, default: 'year'
      attribute :residual_value, :decimal, default: 0
      attribute :currency, :string
      attribute :rate, :decimal, default: nil
      attribute :depreciation_method, :string, default: 'straight_line'
      attribute :initial_value, :decimal

      before_validation do
        self.start_date ||= parent.record.acquisition_entry&.acquisition_date
      end

      validates :start_date, timeliness: { type: :date }, if: :start_date_is_required?
      validates :expected_lifespan, numericality: { greater_than: 0 }, allow_blank: true
      validates :expected_lifespan_unit, inclusion: { in: %w[day week month year] }, allow_blank: true
      validates :residual_value, numericality: { greater_than_or_equal_to: 0}
      validates :depreciation_method, inclusion: { in: :depreciation_methods }
      validates :rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, if: :rate_is_required?
      validates :initial_value, numericality: { greater_than_or_equal_to: 0 }, if: :initial_value_is_required?

      def rate_is_required?
        depreciation_method_class&.requires_rate?
      end

      def depreciation_method_class
        AssetCore::Entry::Depreciation::Calculator.find_by_method_name(depreciation_method)
      end

      def depreciation_methods
        AssetCore::Entry::Depreciation.depreciation_methods
      end

      def initial_value_is_required?
        return true unless parent
        if parent
          parent.record.acquisition_entry.nil?
        end
      end

      def start_date_is_required?
        if parent
          parent.record.acquisition_entry.nil?
        end
      end

    end

    custom_attributes_definition :data, Attributes

    define_asset_scopes :depreciation do
      depreciation do
        entry_methods do
          depreciation_schedule do |date= Date.today, period= nil|
            get_depreciation_schedule(date: date, period: period)
          end
          accrued_depreciation do |date|
            get_accrued_depreciation(date)
          end
          net_book_value do |date=Date.today|
            get_net_book_value(date)
          end
        end
      end
    end

    class << self
      def depreciation_methods
        Calculator.descendants.map(&:method_name).map(&:to_s)
      end
    end

    def method_class
      data.depreciation_method_class
    end

    def get_depreciation_schedule(date: Date.today, period: nil)
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
    end

    def get_accrued_depreciation(date= Date.today)
      get_depreciation_schedule(date: date).sum { |entry| entry[:value] }
    end

    def get_net_book_value(date= Date.today)
      initial_value - get_accrued_depreciation(date)
    end
  end
end