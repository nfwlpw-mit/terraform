desc 'Run all basic setup tasks for ssl'
task :ssl => ['setup:ssl:generate']

  namespace :ssl do
    desc 'Generate ssl certificates.'
    task :generate do
    require 'hiera'
    require 'openssl'
    hiera     = Hiera.new(config: File.expand_path('config/hiera.yaml'))
    cert_list = ['ss_api', 'ss_drupal', 'ss_webapp', 'ss_media']

    ssl_dir   = File.expand_path('config/ssl_certs')
    FileUtils.mkdir_p(ssl_dir)

    cert_list.each do |cert|
      puts "Checking if cert exists for #{cert}"
      fqdn             = hiera.lookup("#{cert}::fqdn", nil, '')
      ssl_key          = File.expand_path(fqdn + '.key', ssl_dir)
      ssl_csr          = File.expand_path(fqdn + '.csr', ssl_dir)
      ssl_intermediary = File.expand_path(fqdn + '.intermediary.crt', ssl_dir)
      ssl_crt          = File.expand_path(fqdn + '.crt', ssl_dir)
      name             = OpenSSL::X509::Name.parse "C=US/ST=Massachusetts/L=Boston/O=SimpliSafe Inc/CN=#{fqdn}/emailAddress=webmaster@simplisafe.com"

      # Generate an rsa key if it doesn't exist.  Otherwise, create one.
      unless File.exist?(ssl_key)
        puts "Generating new ssl key for #{fqdn}.\n"
        key = OpenSSL::PKey::RSA.new 2048
        open ssl_key, 'w' do |io| io.write key end
      end
      key = OpenSSL::PKey::RSA.new File.read ssl_key

      unless File.exist?(ssl_csr)
        puts "Generating new csr for #{fqdn}.\n"
        csr            = OpenSSL::X509::Request.new
        csr.version    = 0
        csr.subject    = name
        csr.public_key = key.public_key

        csr.sign key, OpenSSL::Digest::SHA256.new

        open ssl_csr, 'w' do |io| io.write csr.to_pem end
      end
      csr = OpenSSL::X509::Request.new File.read ssl_csr

      unless File.exist?(ssl_intermediary)
        puts "Generating new intermediary crt for #{fqdn}.\n"
        FileUtils.touch(ssl_intermediary)
      end

      unless File.exist?(ssl_crt)
        print "Generating new ssl cert for #{fqdn}.\n"
        crt = OpenSSL::X509::Certificate.new
        crt.version    = 2
        crt.serial     = 0
        crt.not_before = Time.now
        crt.not_after  = Time.now + 31536000

        crt.public_key = key.public_key
        crt.subject    = name

        extension_factory = OpenSSL::X509::ExtensionFactory.new nil, crt
        crt.add_extension extension_factory.create_extension('basicConstraints', 'CA:TRUE', true)
        crt.add_extension extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
        crt.add_extension extension_factory.create_extension('subjectKeyIdentifier', 'hash')

        crt.issuer = name
        crt.sign key, OpenSSL::Digest::SHA256.new

        open ssl_crt, 'w' do |io| io.write crt.to_pem end
      end
    end
  end

  desc 'Export certs to get signed.'
  task :export, :csr_zip_file do | t, args |
    require 'zip'

    csr_zip_file = args[:csr_zip_file] || "CSR_export.zip"
    ssl_dir      = File.expand_path('config/ssl_certs')
    FileUtils.mkdir_p(ssl_dir)

    abort ("Export file already exists.") if File.exist? csr_zip_file

    input_filenames = Dir["config/ssl_certs/*.csr"]

    Zip::File.open(csr_zip_file, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        puts "Adding #{File.basename(filename)} to zip bundle."
        zipfile.add(File.basename(filename), filename)
      end

      #zipfile.get_output_stream(csr_zip_file) { |os| os.write }
    end
  end

  desc 'Import signed ssl certificates.'
  task :import, :signed_cert_zip do | t, args |
    require 'zip'

    signed_cert_zip = args[:signed_cert_zip] || "signed_certs.zip"
    ssl_dir         = File.expand_path('config/ssl_certs')


    FileUtils.mkdir_p(ssl_dir)

    Zip::File.open(signed_cert_zip) do |zipfile|
      zipfile.glob('*.crt').each do |filename|
        filename = filename.to_s
        puts "Extracting #{filename} from zip bundle."
        if File.exist?(File.expand_path(filename, ssl_dir))
          backup_timestamp = DateTime.now.to_s
          puts "Backing up #{filename} to #{filename}-#{backup_timestamp}."
          FileUtils.move(File.expand_path(filename, ssl_dir), File.expand_path(filename + '-' + backup_timestamp, ssl_dir))
        end
        zipfile.extract(filename.to_s, File.expand_path(filename.to_s, ssl_dir))
      end
    end
  end
end
