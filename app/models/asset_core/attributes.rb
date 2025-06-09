module AssetCore
  class Attributes

    include StoreModel::Model
    include ActiveModel::Validations::Callbacks

    class_attribute :protected_attributes
    self.protected_attributes = []

    def self.inherited (subclass)
      super(subclass)
      subclass.protected_attributes = self.protected_attributes.dup
    end

    def self.assignable_attributes
      new.attributes.keys.reject{ |att| self.protected_attributes.map(&:to_s).include?(att.to_s) }
    end

  end
end