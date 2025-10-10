# frozen_string_literal: true

require "debug"

RSpec.describe ActiveModelService do
  describe "module structure" do
    it "has a version number" do
      expect(ActiveModelService::VERSION).not_to be_nil
    end

    it "has an error class" do
      expect(ActiveModelService::Error).to be_a(Class)
    end
  end

  describe ".call class method" do
    subject(:service) { LoginService }

    it "responds to call" do
      expect(service).to respond_to(:call)
    end
  end

  describe "service execution" do
    describe "with valid parameters" do
      subject(:service) { LoginService.call(login: "123", pass: "123") }

      it "is valid and successful" do
        expect(service).to be_valid
        expect(service).to be_success
      end

      it "does not expose login attribute at instance level" do
        expect(service).not_to respond_to(:login)
      end
    end

    describe "with missing parameters" do
      subject(:service) { LoginService.call(login: "123") }

      it "is invalid due to missing pass" do
        expect(service).not_to be_valid
        expect(service).not_to be_success
        expect(service.errors.messages[:pass].first).to eq("can't be blank")
      end
    end

    describe "without parameters" do
      subject(:service) { WithoutParamsService.call }

      it "is valid and successful" do
        expect(service).to be_valid
        expect(service).to be_success
        expect(service.result).to eq("ok")
      end
    end

    describe "with invalid credentials" do
      subject(:service) { LoginService.call(login: "123", pass: "12") }

      it "is invalid with custom error message" do
        expect(service).not_to be_valid
        expect(service.errors.messages[:base].last).to eq("Login/pass invalid")
      end

      it "formats errors as string" do
        expect(service.errors_as_string).to eq("first error, Login/pass invalid")
        expect(service.errors_as_string(sep: " | ")).to eq("first error | Login/pass invalid")
      end

      it "formats errors as array" do
        expect(service.errors_messages).to eq(["first error", "Login/pass invalid"])
      end
    end

    describe "without attr_init definition" do
      it "raises an error" do
        expect { LoginServiceWithoutInit.call(login: "123", pass: "123") }
          .to raise_error(ActiveModelService::Error)
      end
    end
  end

  describe "early success functionality" do
    subject(:service) { LoginEarlySuccessService.call(login: "123", pass: "123") }

    it "allows early termination with success" do
      expect(service).to be_valid
      expect(service).to be_success
      expect(service.result).to eq("early success")
    end
  end

  describe "attr_init with block" do
    describe "with valid parameters" do
      subject(:service) { LoginWithAttrInitBlockService.call(login: "123", pass: "123") }

      it "is successful" do
        expect(service).to be_valid
        expect(service.result).to eq("ok")
      end
    end

    describe "with missing login" do
      subject(:service) { LoginWithAttrInitBlockService.call(login: nil, pass: "123") }

      it "fails validation on attr_init" do
        expect(service).not_to be_success
        expect(service.errors.full_messages.join).to include("Login can't be blank")
        expect(service.form_init).not_to be_valid
        expect(service.form_init.errors.messages[:login]).to include("can't be blank")
      end
    end

    describe "with invalid credentials" do
      subject(:service) { LoginWithAttrInitBlockService.call(login: "1", pass: "123") }

      it "fails service validation while attr_init is valid" do
        expect(service).not_to be_valid
        expect(service.errors.full_messages.join).to include("Login/pass invalid")
        expect(service.form_init).to be_valid
      end
    end

    describe "passing FormInit instance" do
      let(:form) { LoginWithAttrInitBlockService::FormInit.new(login: "123", pass: "123") }
      subject(:service) { LoginWithAttrInitBlockService.call(form) }

      it "accepts FormInit instance as parameter" do
        expect(service).to be_valid
        expect(service.result).to eq("ok")
      end
    end

    describe "with invalid FormInit instance" do
      let(:invalid_form) { FormInitBlockService::FormInit.new(login: "123", pass: "123") }

      it "raises error for incompatible FormInit" do
        expect { LoginWithAttrInitBlockService.call(invalid_form) }
          .to raise_error(ActiveModelService::Error)
      end
    end
  end

  describe "error handling" do
    subject(:service) { LoginErrorsService.call(login: "123", pass: "123") }

    it "accumulates multiple errors" do
      expect(service).not_to be_valid
      expect(service.errors.messages[:base].count).to eq(2)
      expect(service.errors.messages[:base].first).to eq("fail 1")
      expect(service.errors.messages[:base].last).to eq("fail 2")
    end
  end

  describe "messaging system" do
    describe "with default messages" do
      subject(:service) { LoginMessageService.call(login: "123", pass: "123") }

      it "includes all message types" do
        expect(service.messages).to include("default message")
        expect(service.messages).to include("warning message")
        expect(service.messages).to include("my custom message type")
        expect(service).to be_valid
      end

      it "formats messages as string with different separators" do
        expected_default = "default message, warning message, my custom message type"
        expected_pipe = "default message | warning message | my custom message type"
        expected_warning_only = "warning message"

        expect(service.messages_as_string).to eq(expected_default)
        expect(service.messages_as_string(sep: " | ")).to eq(expected_pipe)
        expect(service.messages_as_string(sep: " | ", type: :warning)).to eq(expected_warning_only)
      end

      it "filters messages by type" do
        expect(service.messages_for(:default)).to include("default message")
        expect(service.messages_for(:warning)).to include("warning message")
        expect(service.messages_for(:hard_exception)).to include("my custom message type")
      end
    end

    describe "with invalid credentials and messages" do
      subject(:service) { LoginMessageService.call(login: "123", pass: "12") }

      it "includes error messages and is invalid" do
        expect(service.messages).to include("Login/pass invalid")
        expect(service).not_to be_valid
        expect(service.invalid?).to be_truthy
      end
    end

    describe "with empty messages" do
      subject(:service) { LoginEmptyMessageService.call(login: "123", pass: "123") }

      it "has no messages" do
        expect(service.messages).to be_empty
        expect(service.messages_for(:default)).to be_empty
        expect(service.messages_for(:whatever)).to be_empty
        expect(service).to be_valid
      end
    end
  end

  describe "instance initialization and execution" do
    describe "with valid parameters" do
      subject(:service) { LoginService.new(login: "123", pass: "123").call_now }

      it "is valid when called via instance" do
        expect(service).to be_valid
      end
    end

    describe "with missing parameters" do
      subject(:service) { LoginService.new(login: "123").call_now }

      it "validates via active model" do
        expect(service).not_to be_valid
        expect(service.errors.messages[:pass].first).to eq("can't be blank")
      end
    end

    describe "with invalid credentials" do
      subject(:service) { LoginService.new(login: "123", pass: "12").call_now }

      it "fails validation in call logic" do
        expect(service).not_to be_valid
        expect(service.errors.messages[:base].last).to eq("Login/pass invalid")
      end
    end
  end
end
