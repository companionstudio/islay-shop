module IslayShop
  module MetaData
    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
        extend ClassMethods

        class_attribute :_metadata
      end
    end

    module InstanceMethods
      def data_column
        @data_column = self[_metadata.col] || {}
      end

      def metadata_attributes
        _metadata.attributes
      end

      def has_metadata?
        !!_metadata
      end
    end

    module ClassMethods
      def metadata(col, &blk)
        self._metadata = Attributes.new(self, col, &blk)
      end
    end

    class ExistingAttributeError < StandardError
      def initialize(col, model)
        @message = "Attribute :#{col} is already defined on the model #{model.to_s}"
      end

      def to_s
        @message
      end
    end

    class Attributes
      include Islay::Coercion

      attr_reader :col, :attributes

      def initialize(model, col, &blk)
        @col        = col
        @model      = model
        @attributes = {}

        instance_eval(&blk)
      end

      def enum(name, opts = {})
        define_attribute(name, :enum, :string, opts)
      end

      def string(name, opts = {})
        define_attribute(name, :string, :string, opts)
      end

      def boolean(name, opts = {})
        define_attribute(name, :boolean, :boolean, opts)
      end

      def integer(name, opts = {})
        define_attribute(name, :integer, :integer, opts)
      end

      def float(name, opts = {})
        define_attribute(name, :float, :float, opts)
      end

      private

      def define_validations(name, opts)
        if opts[:required]
          @model.validates_presence_of(name)
        end

        if opts[:format]
          @model.validates_format_of(name, opts[:format])
        end

        if opts[:length]
          @model.validates_length_of(name, opts[:length])
        end

        if opts[:values]
          values = opts[:values].is_a?(Hash) ? opts[:values].keys : opts[:values]
          @model.validates_inclusion_of(name, :in => values, :allow_nil => true)
        end
      end

      def define_attribute(name, type, primitive, opts)
        raise ExistingAttributeError.new(name, @model) if column_names.include?(name)

        @model.attr_accessible name
        @model.class_eval %{
          def #{name}
            data_column['#{name}']
          end

          def #{name}=(v)
            self[_metadata.col] = data_column.merge('#{name}' => _metadata.coerce_#{primitive}(v))
          end
        }

        define_validations(name, opts)
        @attributes[name] = opts.merge!(:type => type)
      end

      def column_names
        @column_names ||= @model.columns.map {|c| c.name.to_sym}
      end
    end # Attributes
  end # MetaData
end #IslayShop
