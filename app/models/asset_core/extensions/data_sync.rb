module AssetCore
  module Extensions
    module DataSync
      def data_sync(data)
        each do |record|
          raise "data_sync method must be implemented!" unless record.respond_to?(:data_sync)
          record.data_sync(data)
        end
      end
    end
  end
end