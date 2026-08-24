# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Plugin::Base do
  before { Dcc::Plugin.reset! }
  after { Dcc::Plugin.reset! }

  let(:plugin_class) do
    Class.new do
      include Dcc::Plugin::Base
    end
  end

  let(:rule) do
    Class.new do
      def check_on(_dcc)
        []
      end
    end
  end

  it "registers a validator through the class-level helper" do
    plugin_class.register_validator(rule)
    expect(Dcc::Plugin.all(:validators)).to include(rule)
  end

  it "returns the rule class from register_validator" do
    expect(plugin_class.register_validator(rule)).to be(rule)
  end

  it "rejects an instance where a rule class was expected" do
    expect { plugin_class.register_validator(rule.new) }
      .to raise_error(ArgumentError, /got an instance of/)
  end

  it "rejects a class that does not define check_on" do
    expect { plugin_class.register_validator(Class.new) }
      .to raise_error(ArgumentError, /responding to #check_on/)
  end

  # Every real rule in the gem subclasses `Rules::Base` and defines no
  # `check_on` of its own, so the guard has to see the inherited one.
  describe "a rule that defines no check_on of its own" do
    let(:subclass) { Class.new(rule) }

    it "carries no check_on of its own" do
      expect(subclass.instance_methods(false)).not_to include(:check_on)
    end

    it "inherits check_on from its superclass" do
      expect(subclass.instance_method(:check_on).owner).to be(rule)
    end

    it "is accepted on that inherited method alone" do
      plugin_class.register_validator(subclass)
      expect(Dcc::Plugin.all(:validators)).to include(subclass)
    end
  end
end
