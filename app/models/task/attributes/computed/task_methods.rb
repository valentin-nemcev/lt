module Task
  module Attributes
  module Computed
  module TaskMethods

    extend ActiveSupport::Concern

    module ClassMethods
      def has_computed_attribute(attribute, opts = {}, &computer)
        opts[:computer] = computer
        computed_attributes_opts[attribute] = opts
      end

      def computed_attributes
        computed_attributes_opts.keys
      end

      def attributes
        computed_attributes | editable_attributes
      end

    end

    included do |base|
      base.class_attribute :computed_attributes_opts
      self.computed_attributes_opts ||= {}
    end

    def initialize(attrs = {})
      super
    end


    def computed_attribute_revisions(args = {})
      attribute = args[:for]
      # unless attribute
      #   return self.class.attributes.flat_map do |attribute|
      #     attribute_revisions(args.merge for: attribute)
      #   end
      # end
      period = args[:in] || TimeInterval.for_all_time
      opts = computed_attributes_opts.fetch attribute

      attribute_computer = opts[:computer]
      depended_on_attributes = Array(opts[:computed_from][:self])

      current_values = Hash.new
      depended_on_attributes.
        map do |attr|
          last_editable_attribute_revision(for: attr, on: period.beginning)
        end.
        compact.
        map do |revision|
          name, value = revision.attribute_name, revision.updated_value
          current_values[name] = value
        end

      depended_on_attributes.
        flat_map { |attr|
          # if attr == attribute
            editable_attribute_revisions for: attr, in: period
          # else
            # attribute_revisions for: attr, in: period
          # end
        }.
        sort_by(&:updated_on).
        map do |revision|
          name, value = revision.attribute_name, revision.updated_value
          current_values[name] = value
          computer_arguments = depended_on_attributes.map do |attribute_name|
            current_values[attribute_name]
          end
          computed_value = attribute_computer.(*computer_arguments)
          Computed::Revision.new \
            owner: self,
            attribute_name: attribute,
            updated_value: computed_value,
            updated_on: revision.updated_on
        end

    end
  end
  end
  end
end
