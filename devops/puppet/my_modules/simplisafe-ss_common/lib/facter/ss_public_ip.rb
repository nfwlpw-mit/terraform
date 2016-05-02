# Facts to abstract out the external and internal IP available independent of which environment we deploy to.

Facter.add(:external_ip) do
  setcode do


    case Facter.value(:lsbdistid)

    when /Ubuntu/
      case Facter.value(:virtual)
      when /virtualbox|parallels/
        Facter.value(:ipaddress_eth1)
      when /xenu|xenhvm/
        # Check if we are in AWS
        if ! Facter.value(:ec2_metadata).nil?
          Facter.value(:ec2_public_ipv4)
        end
      end


    when /CentOS/
      case Facter.value(:virtual)
      when /virtualbox/
        case Facter.value(:lsbmajdistrelease)
        when /6/
          Facter.value(:ipaddress_eth1)
        else
          Facter.value(:ipaddress_enp0s8)
        end
      when /parallels/
        Facter.value(:ipaddress_eth1)
      when /xenu|xenhvm/
        # Check if we are in AWS
        if ! Facter.value(:ec2_metadata).nil?
          Facter.value(:ec2_public_ipv4)
        end
      end


    end
  end
end

Facter.add(:internal_ip) do
  setcode do

    case Facter.value(:lsbdistid)
    when /Ubuntu/
      case Facter.value(:virtual)
      when /virtualbox|parallels/
        Facter.value(:ipaddress_eth1)
      when /xenu|xenhvm/
        # Check if we are in AWS
        if ! Facter.value(:ec2_metadata).nil?
          Facter.value(:ec2_local_ipv4)
        end
      end

    when /CentOS/
      case Facter.value(:virtual)
      when /virtualbox/
        case Facter.value(:lsbmajdistrelease)
        when /6/
          Facter.value(:ipaddress_eth1)
        else
          Facter.value(:ipaddress_enp0s8)
        end
      when /parallels/
        Facter.value(:ipaddress_eth1)
      when /xenu|xenhvm/
        # Check if we are in AWS
        if ! Facter.value(:ec2_metadata).nil?
          Facter.value(:ec2_local_ipv4)
        end
      end
    end
  end
end

