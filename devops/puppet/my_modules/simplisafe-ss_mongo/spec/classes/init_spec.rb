require 'spec_helper'
describe 'ss_mongo' do

  context 'with defaults for all parameters' do
    it { should contain_class('ss_mongo') }
  end
end
