While this is no longer a supported configuration, some people are still using NFS instead of shared file systems for virtualbox and parallels.  Documentation is kept here for posterity till we are sure everyone is off of NFS.

Before building your dev environment you will need to make a change to your local sudoers file. This is necessary ONLY if you are using your local git revision (set in ss_overrides.yaml as stated above). This change will allow Vagrant to modify the system files (necessary for configuring NFS) without prompting for your credentials. Please do the following:
    
1. Run the command => sudo visudo
2. Copy the following to the sudoers file (Be sure to replace %admin with your Mac username): 
       
        Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
        Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
        Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
        %admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE
    
3. Write and quit out of the sudoers file