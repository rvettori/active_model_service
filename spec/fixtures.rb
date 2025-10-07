# frozen_string_literal: true

class LoginService < ActiveModelService::Call
  attr_init :login, :pass

  validates :login, :pass, presence: true

  def call
    error("first error") if @login != @pass
    error!("Login/pass invalid") if @login != @pass

    "ok"
  end
end

class WithoutParamsService < ActiveModelService::Call
  def call
    "ok"
  end
end

class LoginWithAttrInitBlockService < ActiveModelService::Call
  form_init do
    attribute :login, :string
    attribute :pass, :string

    validates :login, :pass, presence: true
  end

  def call
    error("first error") if login != pass
    error!("Login/pass invalid") if login != pass

    "ok"
  end
end

class FormInitBlockService < ActiveModelService::Call
  form_init do
    attribute :login, :string
    attribute :pass, :string
  end

  def call
    "ok"
  end
end

class LoginServiceWithoutInit < ActiveModelService::Call
  attr_init :login

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

class LoginEarlySuccessService < ActiveModelService::Call
  attr_init :login, :pass

  validates :login, :pass, presence: true

  def call
    success!("early success")

    "ok"
  end
end
