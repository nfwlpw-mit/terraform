require 'spec_helper'
describe 'ss_redis' do

  context 'with defaults for all parameters' do
    it { should contain_class('ss_redis') }
  end
end
