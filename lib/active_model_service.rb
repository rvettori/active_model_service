# frozen_string_literal: true

require_relative "active_model_service/version"
require "active_model"

module ActiveModelService
  class Error < StandardError; end

  class Call
    include ActiveModel::Validations
    include ActiveModel::AttributeAssignment

    class ValueError < StandardError; end

    attr_reader :result, :valid

    def initialize(attributes = {})
      @messages = []
      instance = self
      attributes.each do |k, v|
        raise Error, "Attribute #{k} is a reserve word!" if %i[result error valid call messages].include?(k.to_sym)

        # TODO: Validate call_params
        unless instance.methods.include?(k.to_sym)
          raise Error, "Attribute is not defined! Add `call_params :#{k}` in #{instance.class}"
        end

        instance.instance_variable_set("@#{k}".to_sym, v)
      end
      instance._call
    end

    def _call
      @result = call if send(:run_validations!)
    rescue Error => e
      puts e.message
    end

    def valid?(_ = nil)
      @valid = errors.empty?
    end

    def self.call(attributes = {})
      new(attributes)
    end

    # Add error to :base continue
    def error(message)
      errors.add(:base, message)
    end

    # Add error to :base and stop
    def error!(message)
      error(message)
      raise Error, message
    end

    # Add message to messages
    # type: :default, :info, :warning, :success, :whatever...
    # default type: :default
    def message(message, type = :default)
      @messages << { message: message, type: type.to_sym }
    end

    # Return all messages
    def messages
      @messages.map { |m| m[:message] }
    end

    # Return all messages of type
    def messages_of(message_type)
      msg = @messages.select { |m| m[:type] == message_type.to_sym }
      msg.map { |m| m[:message] }
    end

    class << self
      def call_params(*attribute_names)
        # define_method(:call_params) do |*_args|
        #   instance_variable_set(:@call_params, attribute_names.dup)
        # end

        attribute_names.each do |attribute_name|
          define_method(attribute_name.to_sym) do
            instance_variable_get(:"@#{attribute_name}")
          end
        end
      end
    end
  end
end
