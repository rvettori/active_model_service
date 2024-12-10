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

    def self.rescue_from(error_class, with:)
      define_method(:rescue_with_handler) do |error|
        send(with, error)
      end

      define_method(:_call) do
        @result = call if valid?
      rescue error_class => e
        rescue_with_handler(e)
      end
    end

    def initialize(attributes = {})
      @messages = []
      instance = self
      attributes.each do |k, v|
        raise Error, "Attribute #{k} is a reserve word!" if %i[result error valid call messages].include?(k.to_sym)

        # TODO: raise error at nexet version
        unless instance.respond_to?(:attr_init) && attr_init&.include?(k.to_sym)
          msg = "WARNING!!!! Attribute is not defined! Add `attr_init :#{k}` in #{instance.class}"
          # raise Error, msg
          puts msg
        end

        instance.instance_variable_set("@#{k}".to_sym, v)
      end
    end

    def call_now
      begin
        @result = call if send(:run_validations!)
      rescue Error => e
        puts e.message
      end

      self
    end

    def valid?(_ = nil)
      @valid = errors.empty?
    end

    def self.call(attributes = {})
      me = new(attributes)
      me.call_now
      me
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
      def attr_init(*attribute_names)
        define_method(:attr_init) do
          instance_variable_set(:@attr_init, attribute_names.dup)
        end

        # TODO: Analize if Remove reader to next version
        attribute_names.each do |attribute_name|
          define_method(attribute_name.to_sym) do
            instance_variable_get(:"@#{attribute_name}")
          end
        end
      end
    end
  end
end
