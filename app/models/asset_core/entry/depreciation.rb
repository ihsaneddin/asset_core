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
      attribute :depreciation_method_class, :string
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

      after_validation do
        self.depreciation_method_class = AssetCore::Entry::Depreciation::Calculator.find_by_method_name(depreciation_method)
      end

      def rate_is_required?
        depreciation_method_class&.requires_rate?
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

    define_asset_scopes :depreciation #do
    #   depreciation do
    #     functions do
    #       depreciation_schedule do |date= Date.today, period= nil|
    #         get_depreciation_schedule(date: date, period: period)
    #       end
    #       accrued_depreciation do |date|
    #         get_accrued_depreciation(date)
    #       end
    #       net_book_value do |date=Date.today|
    #         get_net_book_value(date)
    #       end
    #     end
    #   end
    # end

    class << self
      def depreciation_methods
        Calculator.descendants.map(&:method_name).map(&:to_s)
      end
    end

    def method_class
      data.depreciation_method_class
    end

  end
end