require 'spec_helper'

describe 'ironic::db::postgresql' do

  shared_examples_for 'ironic::db::postgresql' do
    let :req_params do
      { :password => 'ironicpass' }
    end

    let :pre_condition do
      'include postgresql::server'
    end

    context 'with only required parameters' do
      let :params do
        req_params
      end

      it { is_expected.to contain_class('ironic::deps') }

      it { is_expected.to contain_openstacklib__db__postgresql('ironic').with(
        :user       => 'ironic',
        :password   => 'ironicpass',
        :dbname     => 'ironic',
        :encoding   => nil,
        :privileges => 'ALL',
      )}
    end

  end

  on_supported_os({
    :supported_os   => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge(OSDefaults.get_facts({
          # puppet-postgresql requires the service_provider fact provided by
          # puppetlabs-postgresql.
          :service_provider => 'systemd'
        }))
      end

      it_behaves_like 'ironic::db::postgresql'
    end
  end

end
