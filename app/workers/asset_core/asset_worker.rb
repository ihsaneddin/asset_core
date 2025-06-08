module AssetCore
  class AssetWorker < AssetCore.config.sidekiq.worker_class_constant

    sidekiq_options(**AssetCore.config.sidekiq.options)
    self.model = nil

    def data_sync(asset_class, asset_id)
      asset_constant = asset_class.constantize
      return unless asset_constant.include?(::AssetCore.decorators.asset_methods)
      asset = asset_constant.find(asset_id)
      if asset
        asset.asset_sync_data
      end
    end

  end
end