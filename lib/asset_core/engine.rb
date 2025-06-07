require 'sidekiq'
require 'sidekiq-scheduler'

module AssetCore
  class Engine < ::Rails::Engine
    isolate_namespace AssetCore
    config.generators.api_only = true

    config.to_prepare do
      unless Rails.env.production?
        Dir.glob(AssetCore::Engine.root.join("app/models/asset_core/**/*.rb")).each do |file|
          require_dependency file
        end
      end
    end

    config.after_initialize do |app|
      Sidekiq.configure_server do |cfg|
        cfg.on :startup do
          AssetCore::Engine.load_sidekiq_scheduler(cfg)
        end
      end
    end

    class << self

      def load_sidekiq_scheduler(cfg)
        sidekiq_scheduler_version = SidekiqScheduler::VERSION.to_i
        schedule_file = AssetCore::Engine.root.join('config', 'asset_core_schedule.yml')
        asset_core_schedule = YAML.load_file(schedule_file).dig(:versions, sidekiq_scheduler_version)
        case sidekiq_scheduler_version
        when 4
          if asset_core_schedule
            schedule = schedule.merge(asset_core_schedule)
            cfg.schedule= schedule
            queues = cfg[:queues] || []
          queues = queues + [AssetCore.config.sidekiq.options[:queue]]
            SidekiqScheduler::Scheduler.instance.reload_schedule!
          end
        when 5
          if asset_core_schedule
            schedule = (Sidekiq.schedule || {}).dup
            schedule = schedule.merge(asset_core_schedule)
            Sidekiq.schedule= schedule
            Sidekiq.default_configuration.queues= cfg[:queues] + [AssetCore.config.sidekiq.options[:queue]]
            SidekiqScheduler::Scheduler.instance.reload_schedule!
          end
        end
      end

    end

  end
end
