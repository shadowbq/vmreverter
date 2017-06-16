# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/vmreverter/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "vmreverter"
  s.authors     = ["shadowbq"]
  s.email       = ["shadowbq@gmail.com"]
  s.homepage    = "https://github.com/shadowbq/vmreverter"
  s.summary     = %q{Revert VM to previous snapshots }
  s.description = s.summary

  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.version       = Vmreverter::VERSION
  s.licenses      = ["BSD3", "APACHE2"]
  s.required_ruby_version = '>= 2.2.7'

  s.add_development_dependency 'bundler', '~> 1.0'

  # Testing dependencies
  s.add_development_dependency 'rake'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'pry'


  # Run time dependencies
  s.add_runtime_dependency 'json', '~> 2.0.3'
  # Fix bug with interdepency of rbnmomi and nokogiri https://github.com/vmware/rbvmomi/issues/31
  s.add_runtime_dependency 'nokogiri', '~> 1.5.5'
  s.add_runtime_dependency 'rbvmomi', '~> 1.9.4'
  s.add_runtime_dependency 'blimpy', '~> 0.6.7'
end
