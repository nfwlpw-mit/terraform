# Using certificates in dev environments.

## Generating certificates
Certificates are only valid if they match the fully qualified domain name (FQDN) portion of the url exactly.  For example, in the url `https://test.example.com:8000/path/test.html` the FQDN would be `test.example.com`.  In order to generate the correct certificates, the FQDN for each exposed web service can be defined in ss_overrides.yaml.  See the confing/ss_overrides.yaml.example file for examples.

Once the config is set, run the command `rake setup` to run the full setup scripts or `rake setup:ssl:generate` to run only the ssl cert generation.

At this point, you have self signed certificates which allows you to bring up your dev environment.  You will still get ssl warnings in your browser and certain functionality, like the mobile apps, will reject the certs outright.


# Improving your certs

If you want to get rid of the warnings and enable full functionality, you have to trust your certs on your client devices.  To do this there are two options.

## Manually trusting and sharing each cert:

The first option is more labor and more maintenance, however in a pinch you can do it without having to wait to have your certs signed.  To do this, you can collect the .crt files out of the `config/ssl_certs` directory and add them to the trust on all devices accessing your dev environment over SSL/TLS.  You will also have to share these .crt files with other developers if they want to be able to work in your environment without issues.

Once the certs are collected, you should follow the instructions from the [SimpliSafe wiki](https://simplisafe.atlassian.net/wiki/display/IT/Trusting+the+SimpliSafe+Internal+CA) to add each cert to a client.  When following the instructions, you should substitute the crt files you have collected for the crt linked in the documentation.

## Get your certs trusted by the simplisafe internal CA:

This will allow you to have your certs signed by a central CA.  Then, if the client trusts the CA, it trusts any certs signed by the CA without any further work.  This makes working with shared resources (dev phones) or working with other folks environments significantly easier and is the recommended approach.  In order to do so, you can run the command `rake setup:ssl:export` from your devops repo.  This will export your CSR to a file named `CSR_export.zip` by default.

Add the generated file as an attachment to an email and send it to techops@simplisafe.com.  When the certs have been signed, you should get an email back with a file named `signed_certs.zip`.  Move that file to the root of your devops repo and run `rake setup:ssl:import`.

Once completed, you can follow the instructions from the [SimpliSafe wiki](https://simplisafe.atlassian.net/wiki/display/IT/Trusting+the+SimpliSafe+Internal+CA) for any client that is not already configured to trust the SimpliSafe internal CA.