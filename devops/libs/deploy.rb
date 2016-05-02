desc "Deploy api"
task :deploy_api do
  Dir.chdir "terraform"
  old_instances = `terraform output api_instances`.split(' ')

  old_instances.each_with_index do |instance, index|
    sleep(90) if (index != 0)
    system "terraform taint aws_instance.api.#{index}"
    system 'terraform apply -var-file credentials.tfvars -var-file terraform.tfvars'
  end

  new_instances = `terraform output api_instances`.split(' ')
  old_instances_remaining = Array.new()

  old_instances.each do |old_instance|
    if (new_instances.include? old_instance) then
      old_instances_remaining.push(old_instance)
    end
  end

  if old_instances_remaining.any? then
    puts 'Deploy failed.  Old instances still remaining!  This requires manual intervention!'
    puts 'Instances that failed to be replaced: ' + old_instances_remaining.join(', ')
    abort
  end
end
