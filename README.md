# ActiveModelService

Make your active model as service object.

Standardize service calls using `call` method.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_model_service'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_model_service

## Usage

Define the service class and invoke your bussiness logic by method `call`.
Use defaults validators of activemodel.
When you need raise error, use `error!('error and stop')`. This error is shown at :base key errors of activemodel.
When you need add multiples errors base, use `error('my error message without stop')`.
You can use all behaviors of activemodel.

### Basic Example

```ruby
class LoginService < ActiveModelService::Call
    attr_init :login, :pass

    validates :login, :pass, presence: true

    def call
      error!('Login/pass invalid') if login != pass

      message 'successfully logged in'

      'login is valid'
    end
end

# Success
login_service = LoginService.call(login: 'admin', pass: 'admin')
login_service.success? # => true (alias for valid?)
login_service.valid? # => true
login_service.invalid? # => false
login_service.errors # => {}
login_service.messages # => ['successfully logged in']
login_service.result # => "login is valid"

# Validation error
login_service = LoginService.call(login: 'admin', pass: nil)
login_service.valid? # => false
login_service.invalid? # => true
login_service.errors.full_messages # => ["Pass can't be blank"]
login_service.result # => nil

# add_error validation
login_service = LoginService.call(login: 'admin', pass: 'wrong')
login_service.valid? # => false
login_service.errors.full_messages # => ["Login/pass invalid"]
login_service.errors_as_string # => "Login/pass invalid"
login_service.result # => nil
```

### Advanced Usage with `form_init`

For more complex scenarios, you can use `form_init` to define attributes with types, defaults, and validations in a dedicated form object.

```ruby
class AdvancedLoginService < ActiveModelService::Call
  form_init do
    attribute :login, :string
    attribute :pass, :string
    attribute :remember_me, :boolean, default: false

    validates :login, :pass, presence: true
  end

  def call
    # You can access attributes directly
    error!('Login/pass invalid') if login != pass

    message 'successfully logged in'

    { status: 'ok', remember: remember_me }
  end
end

# Call with valid data
service = AdvancedLoginService.call(login: 'admin', pass: 'admin', remember_me: true)
service.success?      # => true
service.result        # => { status: 'ok', remember: true }
service.form_init.login # => "admin"

# Call with invalid data
service = AdvancedLoginService.call(login: 'admin')
service.success?      # => false
service.errors.full_messages.join # => "Pass can't be blank"
service.form_init.valid? # => false
```

### Early success

You can stop the execution and return a success result at any point in the `call` method using `success!`.

```ruby
class EarlySuccessService < ActiveModelService::Call
  attr_init :login, :pass

  def call
    success!('Already logged in') if @login == 'cached'

    # ... more logic
    'ok'
  end
end

service = EarlySuccessService.call(login: 'cached', pass: 'any')
service.success? # => true
service.result   # => "Already logged in"
```

### Handling Errors and Messages

#### `errors_as_string`

Get all error messages as a single string.

```ruby
service = LoginService.call(login: '123', pass: '12') # This service adds two errors
service.errors.full_messages # => ["first error", "Login/pass invalid"]
service.errors_as_string # => "first error, Login/pass invalid"
service.errors_as_string(sep: ' | ') # => "first error | Login/pass invalid"
```

#### Importing errors

You can import errors from another service or an `ActiveRecord` model.

```ruby
class AnotherService < ActiveModelService::Call
  attr_init :param

  def call
    error!("error from another service")
  end
end

class MainService < ActiveModelService::Call
  attr_init :login

  def call
    another_service = AnotherService.call(param: 'test')
    error(another_service) if another_service.invalid?
  end
end

service = MainService.call(login: 'test')
service.invalid? # => true
service.errors_as_string # => "error from another service"
```

#### Messages

Add informational messages that don't imply failure. You can categorize them by type.

```ruby
class MessageService < ActiveModelService::Call
  attr_init :login

  def call
    message('Default message')
    message('A warning', :warning)
    message('Something important', :alert)
    'ok'
  end
end

service = MessageService.call(login: 'test')
service.success? # => true
service.messages # => ["Default message", "A warning", "Something important"]
service.messages_for(:warning) # => ["A warning"]
service.messages_as_string # => "Default message, A warning, Something important"
service.messages_as_string(type: :alert) # => "Something important"
```

### Alternative instantiation

For testing or specific scenarios, you can instantiate the service first and then execute it.

```ruby
login_service = LoginService.new(login: 'admin', pass: 'admin')
login_service.call_now
login_service.valid? # => true
login_service.result # => "login is valid"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rvettori/active_model_service.
