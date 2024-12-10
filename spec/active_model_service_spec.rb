# frozen_string_literal: true

require "debug"

class LoginService < ActiveModelService::Call
  attr_reader :login, :pass

  validates :login, :pass, presence: true

  def call
    error!("Login/pass invalid") if @login != @pass

    "ok"
  end
end

class LoginErrorsService < ActiveModelService::Call
  attr_init :login, :pass

  validates :login, :pass, presence: true

  def call
    error("fail 1")
    error("fail 2")
    "ok"
  end
end

class LoginMessageService < ActiveModelService::Call
  attr_init :login, :pass

  validates :login, :pass, presence: true

  def call
    if @login != @pass
      message("Login/pass invalid")
      error!("Login/pass invalid")
    end

    message("default message")
    message("warning message", :warning)
    message("my custom message type", :hard_exception)

    "ok"
  end
end

class LoginEmptyMessageService < ActiveModelService::Call
  attr_init :login, :pass

  validates :login, :pass, presence: true

  def call
    "ok"
  end
end

RSpec.describe ActiveModelService do
  it "has a version number" do
    expect(ActiveModelService::VERSION).not_to be nil
  end

  it "has a error class" do
    expect(ActiveModelService).respond_to?(:Error)
  end

  describe "call" do
    let(:login_service) { LoginService }
    let(:login_service_valid) { LoginService.call(login: "123", pass: "123") }
    let(:login_service_invalid) { LoginService.call(login: "123") }
    let(:login_service_call_invalid) { LoginService.call(login: "123", pass: "12") }

    let(:login_message_service_valid) { LoginMessageService.call(login: "123", pass: "123") }
    let(:login_message_service_invalid) { LoginMessageService.call(login: "123", pass: "12") }
    let(:login_message_service_empty) { LoginEmptyMessageService.call(login: "123", pass: "123") }

    it "must respond to call" do
      expect(LoginService).respond_to?(:call)
    end

    it "must be valid" do
      expect(login_service_valid).to be_valid
    end

    it "must validate by active model validates" do
      expect(login_service_invalid).not_to be_valid
      expect(login_service_invalid.errors.messages[:pass].first).to eq("can't be blank")
    end

    it "must be invalid in call logic at base key" do
      expect(login_service_call_invalid).not_to be_valid
      expect(login_service_call_invalid.errors.messages[:base].first).to eq("Login/pass invalid")
    end

    it "must have default message" do
      expect(login_message_service_valid.messages).to include("default message")
      expect(login_message_service_valid.messages).to include("warning message")
      expect(login_message_service_valid.messages).to include("my custom message type")
      expect(login_message_service_valid).to be_valid
    end

    it "must have default success" do
      expect(login_message_service_valid.messages_of(:default)).to include("default message")
      expect(login_message_service_valid.messages_of(:warning)).to include("warning message")
      expect(login_message_service_valid.messages_of(:hard_exception)).to include("my custom message type")
      expect(login_message_service_valid).to be_valid
    end

    it "must have default message and invalid message" do
      expect(login_message_service_invalid.messages).to include("Login/pass invalid")
      expect(login_message_service_invalid).not_to be_valid
    end

    it "must be empty messages" do
      expect(login_message_service_empty.messages).to be_empty
      expect(login_message_service_empty.messages_of(:default)).to be_empty
      expect(login_message_service_empty.messages_of(:whatever)).to be_empty
      expect(login_message_service_empty).to be_valid
    end

    it "must respond invalid" do
      expect(login_message_service_invalid.invalid?).to be_truthy
    end

    it "must invoke call when run_validation be valid"
    it "must be valid when errors empty"
    it "must raise error when reserved words"
    it "must raise error when attribute is not defined"
  end

  describe "fail" do
    let(:login_errors_service) { LoginErrorsService.call(login: "123", pass: "123") }

    it "must be invalid with thwo errors" do
      expect(login_errors_service).not_to be_valid
      expect(login_errors_service.errors.messages[:base].count).to eq(2)
      expect(login_errors_service.errors.messages[:base].first).to eq("fail 1")
      expect(login_errors_service.errors.messages[:base].last).to eq("fail 2")
      expect(login_errors_service.errors.messages[:base].last).to eq("fail 2")
      expect(login_errors_service).not_to be_valid
    end
  end

  describe "new" do
    let(:login_service) { LoginService }
    let(:login_service_valid) { LoginService.new(login: "123", pass: "123").call_now }
    let(:login_service_invalid) { LoginService.new(login: "123").call_now }
    let(:login_service_call_invalid) { LoginService.new(login: "123", pass: "12").call_now }

    it "must be valid" do
      expect(login_service_valid).to be_valid
    end

    it "must validate by active model validates" do
      expect(login_service_invalid).not_to be_valid
      expect(login_service_invalid.errors.messages[:pass].first).to eq("can't be blank")
    end

    it "must be invalid in call logic at base key" do
      expect(login_service_call_invalid).not_to be_valid
      expect(login_service_call_invalid.errors.messages[:base].first).to eq("Login/pass invalid")
    end
  end
end
