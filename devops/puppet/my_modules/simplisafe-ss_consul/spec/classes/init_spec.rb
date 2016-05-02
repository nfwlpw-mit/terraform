require 'spec_helper'
describe 'ss_consul' do

  context 'with defaults for all parameters' do
    it { should contain_class('ss_consul') }
  end
end
