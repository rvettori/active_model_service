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
When you need raise error, use `error!('error adn stop')`. This erro showin at :base key errors of activemodel.
When you need add multiples errors base, use `error('my error message without stop')`. Need `raise Error` after to stop
You can use all behaviors of activemodel.

Example:

```ruby
class LoginService < ActiveModelService::Call
    attr_reader :login, :pass

    validates :login, :pass, presence: true

    def call
    error!('Login/pass invalid') if @login != @pass

    message 'successfully logged in'

    'login is valid'
    end
end

# Success
login_service = LoginService.call(login: 'admin', pass: 'admin')
login_service.valid? # => true
login_service.invalid? # => false
login_service.errors # => {}
login_service.messages # => ['successfully logged in']
login_service.result # => true

# Validation error
login_service = LoginService.call(login: 'admin', pass: nil)
login_service.valid? # => false
login_service.invalid? # => true
login_service.errors # => {pass: "Can't be blank"}
login_service.messages # => []
login_service.result # => nil

# add_error validation
login_service = LoginService.call(login: 'admin', pass: 'wrong')
login_service.valid? # => false
login_service.invalid? # => true
login_service.errors # => {base: "Login/pass invalid"}
login_service.messages # => []
login_service.result # => nil

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rvettori/active_model_service.
