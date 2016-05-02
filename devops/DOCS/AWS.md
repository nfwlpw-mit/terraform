# Notes for the AWS plugin

If the AWS plugin is installed, it will cause vagrant to fail if credentials aren't available to it.  AWS credentials cannot be stored in either the Vagrantfile or hiera config files in the /config directory as those are uploaded to each instance.  Instead, the following should be added to the file ~/.vagrant.d/Vagrantfile
```
Vagrant.configure("2") do |config|
  config.vm.provider :aws do |aws, override|
    aws.access_key_id = "<< AWS Access Key >>"
    aws.secret_access_key = "<< AWS Secret Key >>"
  end
end

```