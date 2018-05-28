# frozen_string_literal: true

Gem::Specification.new do |s|
    s.name        = 'RazorWork'
    s.version     = '0.0.0'
    s.date        = '2018-05-25'
    s.summary     = 'Allow declarative use of razor-server'
    s.description = 'Put your configs into version control and automate
        synchronisation with razor-server'
    s.authors     = ['Christopher J Tapp']
    s.email       = 'chrisjohntapp@gmail.com'
    s.files       = ['lib/razorwork.rb', 'lib/razorwork/cli.rb',
                     'lib/razorwork/tags.rb', 'data/tags/test.yaml',
                     'bin/razorwork']
    s.require_paths = ['lib']
    s.homepage    = 'http://rubygems.org/gems/razorwork'
    s.license     = 'MIT'
end
