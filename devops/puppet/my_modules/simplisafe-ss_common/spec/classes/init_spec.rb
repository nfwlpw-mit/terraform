require 'spec_helper'
describe 'ss_common' do

  context 'with defaults for all parameters' do
    it { should contain_class('ss_common') }
  end
end
