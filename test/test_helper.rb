# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

# To test RailsMetrics, you need to:
#
#   1) Install latest bundler with "gem install bundler"
#   2) bundle install
#   3) rake prepare
#   4) rake test
#
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  class MockStore < ::MockStore
    def store!(args)
      super

      if args[0] == "rails_metrics.kicker"
        args << :kicked!
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end

  setup do
    wait
    RailsMetrics.set_store { Metric }
  end

  # Execute the block setting the given values and restoring old values after
  # the block is executed.
  def swap(object, new_values)
    old_values = {}
    new_values.each do |key, value|
      old_values[key] = object.send key
      object.send :"#{key}=", value
    end
    yield
  ensure
    old_values.each do |key, value|
      object.send :"#{key}=", value
    end
  end

  def wait
    RailsMetrics.wait
  end

  # Sometimes we need to wait until RailsMetrics push reaches the Queue.
  def wait!
    sleep(0.05)
    wait
  end

  def instrument(*args, &block)
    ActiveSupport::Notifications.instrument(*args, &block)
  end
end