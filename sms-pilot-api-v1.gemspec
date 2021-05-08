# frozen_string_literal: true

require_relative "lib/sms_pilot/version"

Gem::Specification.new do |spec|
  spec.name        =  "sms-pilot-api-v1"
  spec.authors     = ["Sergey Pedan"]
  spec.summary     =  "Simple wrapper around SMS pilot API v1"
  spec.description =  "#{spec.summary}. Version 1 because it returns more data within its standard response"
  spec.email       = ["sergey.pedan@gmail.com"]
  spec.homepage    =  "https://github.com/sergeypedan/#{spec.name}"
  spec.license     =  "MIT"
  spec.version     =   SmsPilot::VERSION

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata = {
    "changelog_uri"     => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/github/sergeypedan/#{spec.name}/master/",
    "homepage_uri"      =>  spec.homepage,
    "source_code_uri"   =>  spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features|pkg)/}) }
  end

  spec.bindir        =  "bin"
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "http", "~> 4"

end
