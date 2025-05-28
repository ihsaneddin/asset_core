module AssetCore
  class EntryReferenceWorker < AssetCore.config.sidekiq.worker_class_constant

    sidekiq_options(**AssetCore.config.sidekiq.options)
    self.model = nil

    def data_sync(reference_class, reference_id)
      ref_constant = reference_class.constantize
      return if ref_constant.include?(AssetCore::Models::Decorators::AssetEntryReference)
      ref = ref_constant.find(reference_id)
      if ref
        ref.asset_entry_sync_data
      end
    end

  end
end