# frozen_string_literal: true

class LoginService < ActiveModelService::Call
  attr_reader :login, :pass

  validates :login, :pass, presence: true

  def call
    add_error("Login/pass invalid") if @login != @pass

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

    it "must invoke call when run_validation be valid"
    it "must be valid when errors empty"
    it "must raise error when reserved words"
    it "must raise error when attribute is not defined"
  end
end
