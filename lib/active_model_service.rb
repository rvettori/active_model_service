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
      instance = self
      attributes.each do |k, v|
        raise Error, "Attribute #{k} is a reserve word!" if %i[result error valid call].include?(k.to_sym)

        unless instance.methods.include?(k.to_sym)
          raise Error, "Attribute is not defined! Add `attr :#{k}` in #{instance.class}"
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
      # new.tap do |instance|
      #   attributes.each do |k, v|
      #     raise Error, "Attribute #{k} is a reserve word!" if %i[result error valid call].include?(k.to_sym)

      #     unless instance.methods.include?(k.to_sym)
      #       raise Error, "Attribute is not defined! Add `attr :#{k}` in #{instance.class}"
      #     end

      #     instance.instance_variable_set("@#{k}".to_sym, v)
      #   end
      #   instance._call
      # end
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
  end
end
