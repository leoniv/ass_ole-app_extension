# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ass_ole/app_extension/version"

Gem::Specification.new do |spec|
  spec.name          = "ass_ole-app_extension"
  spec.version       = AssOle::AppExtension::VERSION
  spec.authors       = ["Leonid Vlasov"]
  spec.email         = ["leoniv.vlasov@gmail.com"]

  spec.summary       = %q{Helper for working with 1C:Enterprise ConfigurationExtension}
  spec.description   = %q{Features for hot plug a ConfigurationExtension to 1C:Enterprise application instance (aka infobase) and some more}
  spec.homepage      = "https://github.com/leoniv/ass_ole-app_extension"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ass_ole'
  spec.add_dependency 'ass_ole-snippets-shared', '~> 0.5'
  spec.add_dependency "ass_maintainer-info_base"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "mocha"
end
