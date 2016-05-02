desc 'Check for MFA certs'
task :mfa do
  unless File.exists?('config/mfa_certs/key_dev.pem')
    puts ''
    puts 'WARNING: The file key_dev.pem could not be found in config/mfa_certs.'
    puts '         MFA on apple devices will not work in your dev environment without this.'
    puts '         In order for MFA to work with apple devices, you will dev certs.'
    puts '         See Kevin or David for help.'
  end

  unless File.exists?('config/mfa_certs/cert_dev.pem')
    puts ''
    puts 'WARNING: The file cert_dev.pem could not be found in config/mfa_certs.'
    puts '         MFA on apple devices will not work in your dev environment without this.'
    puts '         In order for MFA to work with apple devices, you will dev certs.'
    puts '         See Kevin or David for help.'
  end

end