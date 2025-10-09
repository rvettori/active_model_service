# frozen_string_literal: true

require_relative "active_model_service/version"
require "active_model"

module ActiveModelService
  class Error < StandardError; end

  class Call
    include ActiveModel::Validations
    # include ActiveModel::AttributeAssignment

    attr_reader :result, :valid

    def initialize(attributes = {})
      @messages = []

      unless self.class.respond_to?(:attr_init) || self.class.respond_to?(:form_init)
        raise Error,
              "ActiveModelService::Error: (attr_init or form_init) is not defined! #{self.class}"
      end

      if attributes.respond_to?(:attributes) && attributes.is_a?(self.class.const_get("FormInit"))
        attributes = attributes.attributes
      end

      raise Error, "Call params must be a hash or FormInit instance!" unless attributes.is_a?(Hash)

      attributes.each do |k, v|
        raise Error, "Attribute #{k} is a reserve word!" if %i[result error valid call messages].include?(k.to_sym)

        unless send(:attr_init_attributes)&.include?(k.to_sym)
          msg = "ActiveModelService::Error: Attribute is not defined! Add `attr_init :#{k}` in #{self.class}"
          raise Error, msg
        end

        instance_variable_set("@#{k}".to_sym, v) unless self.class.const_defined?(:FormInit)
      end

      return unless self.class.const_defined?(:FormInit)

      instance_variable_set(:@form_init, self.class.const_get("FormInit").new(attributes))
    end

    def call_now
      catch(:early_exit) do
        throw(:early_exit, "error on run_validation!") unless send(:run_validations!)
        throw(:early_exit, "error on validate active_model attribute") unless form_init_valid?

        @result = call if send(:run_validations!)
      end

      self
    end

    def valid?(_ = nil)
      @valid = errors.empty?
    end

    def success?
      valid?
    end

    def success!(result = nil)
      @result = result
      throw(:early_exit)
    end

    def self.call(attributes = {})
      me = new(attributes)
      me.call_now
      me
    end

    def form_init_valid?
      error(form_init) if defined?(form_init) && form_init.respond_to?(:valid?) && !form_init.valid?
      valid?
    end

    def error(message)
      messages = [message].flatten
      messages = message.full_messages if message.respond_to?(:full_messages)

      if message.respond_to?(:errors) && message.errors.respond_to?(:full_messages)
        messages = message.errors.full_messages
      end

      messages.each do |msg|
        errors.add(:base, msg)
      end
    end

    def error!(message)
      error(message)
      throw(:early_exit, message)
    end

    def errors_as_string(sep: ", ")
      errors.full_messages.join(sep) || ""
    end

    def errors_messages
      errors.full_messages
    end

    # Add message to messages
    # type: :default, :info, :warning, :success, :whatever...
    # default type: :default
    def message(message, type = :default)
      @messages << { message: message, type: type.to_sym }
    end

    def messages_as_string(sep: ", ", type: nil)
      messages = type ? messages_for(type) : self.messages
      messages.join(sep)
    end

    # Return all messages
    def messages
      @messages.map { |m| m[:message] }
    end

    # Return all messages of type
    def messages_for(message_type)
      msg = @messages.select { |m| m[:type] == message_type.to_sym }
      msg.map { |m| m[:message] }
    end

    class << self
      def form_init(&block) # rubocop:disable Metrics/MethodLength
        return unless block_given?

        const_set("FormInit", Class.new do
          include ActiveModel::Model
          include ActiveModel::Attributes
          include ActiveModel::Validations
          include ActiveModel::AttributeAssignment

          class_eval(&block)
        end)

        attribute_names = const_get("FormInit").attribute_names.map(&:to_sym)

        attr_reader :form_init

        delegate(*attribute_names, to: :form_init, allow_nil: true)

        define_method(:attr_init_attributes) do
          attribute_names.dup
        end
        private :attr_init_attributes
      end

      def attr_init(*attribute_names)
        # if block_given?
        #   const_set("AttrInit", Class.new do
        #     include ActiveModel::Model
        #     include ActiveModel::Attributes
        #     include ActiveModel::Validations
        #     include ActiveModel::AttributeAssignment

        #     class_eval(&block)
        #   end)

        #   attribute_names = const_get("AttrInit").attribute_names.map(&:to_sym)
        # end

        # attr_reader :attr_init

        # delegate(*attribute_names, to: :attr_init, allow_nil: true) if block_given?

        # Compatibility without attr_init block for prior versions
        # When attr_init block is used, attributes are set in attr_init instance at initialize
        # In future versions, when only accept attr_init block, this code will be removed
        private attr_reader(*attribute_names) # unless block_given?

        define_method(:attr_init_attributes) do
          attribute_names.dup
        end
        private :attr_init_attributes
      end
    end
  end
end
