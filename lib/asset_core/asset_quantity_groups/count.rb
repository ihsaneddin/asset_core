module AssetCore
  module AssetQuantityGroups
    module Count

      extend Core

      def base_unit
        "unit"
      end

      def units
        [
          { name: "unit",    label: "Unit",    factor: 1 },
          { name: "dozen",   label: "Dozen",   factor: 12 },
          { name: "gross",   label: "Gross",   factor: 144 },
          { name: "score",   label: "Score",   factor: 20 }
        ]
      end
    end
  end
end