desc 'Run all basic setup tasks'
task :setup => ['setup:ssl', 'setup:mfa']

namespace :setup do
  load 'libs/setup/ssl.rb'
  load 'libs/setup/mfa.rb'
end