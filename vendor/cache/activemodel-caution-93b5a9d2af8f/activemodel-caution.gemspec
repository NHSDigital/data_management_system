# -*- encoding: utf-8 -*-
# stub: activemodel-caution 6.0.3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activemodel-caution".freeze
  s.version = "6.0.3.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["NCRS Development Team".freeze]
  s.date = "2020-10-12"
  s.description = "Adds cautioning to ActiveModel".freeze
  s.email = []
  s.files = ["lib/active_model".freeze, "lib/active_model/caution".freeze, "lib/active_model/caution/included.rb".freeze, "lib/active_model/caution/railtie.rb".freeze, "lib/active_model/caution/version.rb".freeze, "lib/active_model/cautioner.rb".freeze, "lib/active_model/cautions".freeze, "lib/active_model/cautions.rb".freeze, "lib/active_model/cautions/callbacks.rb".freeze, "lib/active_model/cautions/cautions.rb".freeze, "lib/active_model/cautions/format.rb".freeze, "lib/active_model/cautions/helper_methods.rb".freeze, "lib/active_model/cautions/inclusion.rb".freeze, "lib/active_model/cautions/numericality.rb".freeze, "lib/active_model/cautions/presence.rb".freeze, "lib/active_model/cautions/safety_decision.rb".freeze, "lib/active_model/cautions/with.rb".freeze, "lib/active_model/locale".freeze, "lib/active_model/locale/en.yml".freeze, "lib/active_model/warnings.rb".freeze, "lib/activemodel-caution.rb".freeze]
  s.homepage = "".freeze
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Warnings are non-enforced validations, and otherwise work in the same way.".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<activemodel>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<actionpack>.freeze, ["= 6.0.3.4"])
    s.add_runtime_dependency(%q<railties>.freeze, ["= 6.0.3.4"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4.0"])
    s.add_development_dependency(%q<ndr_dev_support>.freeze, [">= 2.1.1"])
  else
    s.add_dependency(%q<activerecord>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<activemodel>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<activesupport>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<actionpack>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<railties>.freeze, ["= 6.0.3.4"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.4.0"])
    s.add_dependency(%q<ndr_dev_support>.freeze, [">= 2.1.1"])
  end
end
