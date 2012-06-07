module Islay
  module PromotionConfig
    def self.included(klass)
      klass.class_eval do
        validate :check_config
        attr_accessible :config
        class_attribute :_options, :use_qualification, :use_apply

        include InstanceMethods
        extend ClassMethods
      end

      klass._options = {}
      klass.use_qualification = true
      klass.use_apply = false

      # Replaces the configuration of the options for each sub-class. Since this is
      # a hash that gets mutated, if we didn't do this, the classes would share
      # config.
      def klass.inherited(child)
        child._options = {}
        super
      end
    end

    module InstanceMethods

      private

      def check_config
        check = self._options[option].new(config)
        if check.valid?
          true
        else
          # Add errors to base
          false
        end
      end
    end

    module ClassMethods
      def default_option
        self._options['default'] ||= Class.new(Option)
      end

      def option(name, &blk)
        klass = Class.new(Option)
        klass.config(self, &blk)
        self._options[name.to_s] = klass
      end

      def key(type, name, opts = {})
        default_option.send(type, name, opts)
      end
    end

    # This class encapsulates the configuration for a particular type of promotion
    # condition. This class is never used directly, but is instead used as the
    # super-class of anonymous classes that are generated.
    #
    # This is done so that the sub-classes can have their own validations
    # declared against them. Instances can then be created in order to check
    # the config is valid. This could be done differently, but anon-classes
    # and instances for validation are thread-safe.
    class Option
      class KeysMissingError < StandardError

      end

      class QualificationMissing < StandardError

      end

      class ApplyMissing < StandardError

      end

      include ActiveModel::Validations
      include Islay::Coercion

      class_attribute :_keys, :_qualification, :_apply
      self._keys = {}

      def initialize(config)
        config.each {|k, v| send(:"#{k}=", v)}
      end

      # Returns the coerced set of attributes.
      def config
        self._keys.map {|k, v| send(k)}
      end

      # Checks to see if the order passed in qualifies for the condition.
      def self.qualifies?(condition, order)
        case self._qualification
        when Symbol then condition.send(self._qualification, order)
        when Proc   then condition.instance_eval(&self._qualification)
        end
      end

      # Runs the configured apply method against the order passed in.
      def self.apply!(effect, order)
        case self._apply
        when Symbol then effect.send(self._apply, order)
        when Proc   then effect.instance_eval(&self._apply)
        end
      end

      # Just a simple hook for class evaling a block. The block should call the
      # ::key and ::qualification methods in order to add configuration to the
      # class.
      #
      # Raises KeysMissingError if the block doesn't configure any keys.
      # Raises QualificationMissingError if the qualification logic isn't specified.
      def self.config(model, &blk)
        class_eval(&blk)

        raise KeysMissingError      if self._keys.empty?
        raise QualificationMissing  if model.use_qualification and self._qualification.nil?
        raise ApplyMissing          if model.use_apply and self._apply.nil?
      end

      private

      def self.enum(name, opts = {})
        define_attribute(name, :enum, :string, opts)
      end

      def self.string(name, opts = {})
        define_attribute(name, :string, :string, opts)
      end

      def self.boolean(name, opts = {})
        define_attribute(name, :boolean, :boolean, opts)
      end

      def self.integer(name, opts = {})
        define_attribute(name, :integer, :integer, opts)
      end

      def self.float(name, opts = {})
        define_attribute(name, :float, :float, opts)
      end

      def self.define_validations(name, opts)
        if opts[:required]
          validates_presence_of(name)
        end

        if opts[:format]
          validates_format_of(name, opts[:format])
        end

        if opts[:length]
          validates_length_of(name, opts[:length])
        end

        if opts[:values]
          values = opts[:values].is_a?(Hash) ? opts[:values].keys : opts[:values]
          validates_inclusion_of(name, :in => values, :allow_nil => true)
        end
      end

      def self.define_attribute(name, type, primitive, opts)
        attr_reader name

        @model.class_eval %{
          def #{name}=(v)
            @#{name} = coerce_#{primitive}(v)
          end
        }

        define_validations(name, opts)
        self._keys[name] = opts.merge!(:type => type)
      end

      # Specifies the qualification for this option. This may either be a symbol,
      # which will refer to a method on the condition instance or a block, which
      # will be class evalled against the condition instance.
      def self.qualification(method = nil, &blk)
        self._qualification = method ? method : blk
      end

      def self.apply(method = nil, &blk)
        self._apply = method ? method : blk
      end
    end # Option
  end # PromotionsConfig
end # Islay
