module AssetCore
  module Models
    class AssetProxy

      attr_reader :asset, :record

      def self.setup(object)

        cfg = object.record.asset_record.asset_record_scopes_config.dup

        cfg.keys.each do |scope|
          key = cfg.send(key).proxy
          if key
            cfg.functions.keys.each do |funct|
              if object.record.respond_to?(funct)
                method = object.method(funct)
                if method.parameters.any?
                  object.singleton_class.define_method(funct) do |*args|
                    record.send(funct, *args)
                  end
                else
                  object.singleton_class.define_method(funct) do
                    record.send(funct)
                  end
                end
              end
            end
          end
        end

        opts = {
          states: ::AssetCore::State.descendants.inject(cfg.class.build(**{})) do |state, sub|
            state.add(
              sub.state_name.to_sym,
              {
                current: proc {
                  record.send("current_#{sub.state_name}_state")
                },
                state: proc {
                  record.send("current_#{sub.state_name}_state").try(:state_name)
                },
                label: proc {
                  record.send("current_#{sub.state_name}_state").try(:state_label)
                },
                index: proc {
                  record.send("current_#{sub.state_name}_state").try(:index)
                },
                previous: proc {
                  record.send("current_#{sub.state_name}_state")&.previous_state
                },
                previous_state: proc {
                  record.send("current_#{sub.state_name}_state")&.previous_state&.state_name
                },
                previous_label: proc {
                  record.send("current_#{sub.state_name}_state")&.previous_state&.state_label
                },
                previous_index: proc {
                  record.send("current_#{sub.state_name}_state")&.previous_state&.index
                },
              }
            )
          end
        }

        cfg.class.build(**opts)
        cfg.set_context(object)
        object.singleton_class.define_method(:states) do
          cfg.states
        end

      end

      def initialize asset
        @asset = asset
        assoc = @asset.association(:asset_record)
        @record = assoc.reader if assoc.loaded?
        @record ||= assoc.target || assoc.build()
        self.class.setup(self)
      end

      def record
        @record
      end

      def asset
        @asset
      end

    end
  end
end