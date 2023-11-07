#
# Copyright (C) 2015 Red Hat, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for ironic::inspector class
#

require 'spec_helper'

describe 'ironic::inspector' do
  let :pre_condition do
     "class { 'ironic::inspector::authtoken':
        password => 'password',
      }"
  end

  let :params do
    { :package_ensure        => 'present',
      :enabled               => true,
      :pxe_transfer_protocol => 'tftp',
      :auth_strategy         => 'keystone',
      :dnsmasq_interface     => 'br-ctlplane',
      :ramdisk_logs_dir      => '/var/log/ironic-inspector/ramdisk/',
      :add_ports             => 'pxe',
      :keep_ports            => 'all',
      :store_data            => 'none',
      :dnsmasq_ip_subnets    => [{ 'ip_range' =>
                                      '192.168.0.100,192.168.0.120',
                                   'mtu' => '1350'},
                                 { 'tag'      => 'subnet1',
                                   'ip_range' => '192.168.1.100,192.168.1.200',
                                   'netmask'  => '255.255.255.0',
                                   'gateway'  => '192.168.1.254',
                                   'mtu'      => '1350'},
                                 { 'tag'                     => 'subnet2',
                                   'ip_range'                => '192.168.2.100,192.168.2.200',
                                   'netmask'                 => '255.255.255.0',
                                   'gateway'                 => '192.168.2.254',
                                   'classless_static_routes' => [{'destination' => '1.2.3.0/24',
                                                                  'nexthop'     => '192.168.2.1'},
                                                                 {'destination' => '4.5.6.0/24',
                                                                  'nexthop'     => '192.168.2.1'}]},
                                 { 'tag'      => 'subnet3',
                                   'ip_range' => '2001:4888:a03:313a:c0:fe0:0:c200,2001:4888:a03:313a:c0:fe0:0:c2ff',
                                   'netmask'  => 'ffff:ffff:ffff:ffff::',
                                   'gateway'  => '2001:4888:a03:313a:c0:fe0:0:c000' }],
      :dnsmasq_local_ip      => '192.168.0.1',
      :ipxe_timeout          => 0,
      :http_port             => 8088,
      :tftp_root             => '/tftpboot',
      :http_root             => '/httpboot',
    }
  end


  shared_examples_for 'ironic inspector' do

    let :p do
      params
    end

    it { is_expected.to contain_class('ironic::params') }

    it 'installs ironic inspector package' do
      if platform_params.has_key?(:inspector_package)
        is_expected.to contain_package('ironic-inspector').with(
          :ensure => p[:package_ensure],
          :name   => platform_params[:inspector_package],
          :tag    => ['openstack', 'ironic-inspector-package'],
        )
        is_expected.to contain_package('ironic-inspector').that_requires('Anchor[ironic-inspector::install::begin]')
        is_expected.to contain_package('ironic-inspector').that_notifies('Anchor[ironic-inspector::install::end]')
      end

      if platform_params.has_key?(:inspector_dnsmasq_package)
        is_expected.to contain_package('ironic-inspector-dnsmasq').with(
          :ensure => p[:package_ensure],
          :name   => platform_params[:inspector_dnsmasq_package],
          :tag    => ['openstack', 'ironic-inspector-package'],
        )
        is_expected.to contain_package('ironic-inspector-dnsmasq').that_requires('Anchor[ironic-inspector::install::begin]')
        is_expected.to contain_package('ironic-inspector-dnsmasq').that_notifies('Anchor[ironic-inspector::install::end]')
      end
    end

    it 'ensure ironic inspector service is running' do
      is_expected.to contain_service('ironic-inspector').with(
        'hasstatus' => true,
        'tag'       => 'ironic-inspector-service',
      )
    end

    it 'ensure ironic inspector dnsmasq service is running' do
      if platform_params.has_key?(:inspector_dnsmasq_package)
        is_expected.to contain_service('ironic-inspector-dnsmasq').with(
          'hasstatus' => true,
          'tag'       => 'ironic-inspector-dnsmasq-service',
        )
      end
    end

    it 'configures inspector.conf' do
      is_expected.to contain_ironic_inspector_config('DEFAULT/listen_address').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('DEFAULT/auth_strategy').with_value(p[:auth_strategy])
      is_expected.to contain_ironic_inspector_config('DEFAULT/timeout').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('DEFAULT/transport_url').with_value('fake://')
      is_expected.to contain_ironic_inspector_config('DEFAULT/api_max_limit').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('capabilities/boot_mode').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('iptables/dnsmasq_interface').with_value(p[:dnsmasq_interface])
      is_expected.to contain_ironic_inspector_config('processing/ramdisk_logs_dir').with_value(p[:ramdisk_logs_dir])
      is_expected.to contain_ironic_inspector_config('processing/always_store_ramdisk_logs').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('processing/add_ports').with_value(p[:add_ports])
      is_expected.to contain_ironic_inspector_config('processing/keep_ports').with_value(p[:keep_ports])
      is_expected.to contain_ironic_inspector_config('processing/store_data').with_value(p[:store_data])
      is_expected.to contain_ironic_inspector_config('processing/processing_hooks').with_value('$default_processing_hooks')
      is_expected.to contain_ironic_inspector_config('processing/node_not_found_hook').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('discovery/enroll_node_driver').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_inspector_config('port_physnet/cidr_map').with_value('')
    end

    it 'should contain file /etc/ironic-inspector/dnsmasq.conf' do
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with(
        'ensure'  => 'present',
        'require' => 'Anchor[ironic-inspector::config::begin]',
        'content' => /pxelinux/,
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-range=192.168.0.100,192.168.0.120,10m$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option-force=option:mtu,1350$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-range=set:subnet1,192.168.1.100,192.168.1.200,255.255.255.0,10m$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option=tag:subnet1,option:router,192.168.1.254$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option-force=tag:subnet1,option:mtu,1350$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-range=set:subnet2,192.168.2.100,192.168.2.200,255.255.255.0,10m$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option=tag:subnet2,option:router,192.168.2.254$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option=tag:subnet2,option:classless-static-route,1.2.3.0\/24,192.168.2.1,4.5.6.0\/24,192.168.2.1$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-range=set:subnet3,2001:4888:a03:313a:c0:fe0:0:c200,2001:4888:a03:313a:c0:fe0:0:c2ff,64,10m$/
      )
      is_expected.not_to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-option=tag:subnet3,option:router,2001:4888:a03:313a:c0:fe0:0:c000$/
      )
      is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^dhcp-sequential-ip$/
      )
      is_expected.not_to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
        /^log-facility=.*$/
      )
    end
    it 'should contain file /tftpboot/pxelinux.cfg/default' do
      is_expected.to contain_file('/tftpboot/pxelinux.cfg/default').with(
        'owner'   => 'ironic-inspector',
        'group'   => 'ironic-inspector',
        'seltype' => 'tftpdir_t',
        'ensure'  => 'present',
        'require' => 'Anchor[ironic-inspector::config::begin]',
        'content' => /default/,
      )
      is_expected.to contain_file('/tftpboot/pxelinux.cfg/default').with_content(
          /initrd=agent.ramdisk ipa-inspection-callback-url=http:\/\/192.168.0.1:5050\/v1\/continue ipa-inspection-collectors=default/
      )
    end

    context 'when overriding parameters' do
      before :each do
        params.merge!(
          :dhcp_debug                  => true,
          :listen_address              => '127.0.0.1',
          :api_max_limit               => 100,
          :pxe_transfer_protocol       => 'http',
          :additional_processing_hooks => 'hook1,hook2',
          :ramdisk_kernel_args         => 'foo=bar',
          :http_port                   => 3816,
          :tftp_root                   => '/var/lib/tftpboot',
          :http_root                   => '/var/www/httpboot',
          :detect_boot_mode            => true,
          :node_not_found_hook         => 'enroll',
          :discovery_default_driver    => 'pxe_ipmitool',
          :dnsmasq_ip_subnets          => [{'ip_range' => '192.168.0.100,192.168.0.120'}],
          :dnsmasq_dhcp_sequential_ip  => false,
          :dnsmasq_log_facility        => '/var/log/ironic-inspector/dnsmasq.log',
          :add_ports                   => 'all',
          :always_store_ramdisk_logs   => true,
          :port_physnet_cidr_map       => {'192.168.20.0/24' => 'physnet_a',
                                           '2001:db8::/64' => 'physnet_b'},
          :uefi_ipxe_bootfile_name     => 'otherpxe.efi',
        )
      end
      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_inspector_config('DEFAULT/listen_address').with_value(p[:listen_address])
        is_expected.to contain_ironic_inspector_config('DEFAULT/api_max_limit').with_value(100)
        is_expected.to contain_ironic_inspector_config('capabilities/boot_mode').with_value(p[:detect_boot_mode])
        is_expected.to contain_ironic_inspector_config('processing/processing_hooks').with_value('$default_processing_hooks,hook1,hook2')
        is_expected.to contain_ironic_inspector_config('processing/node_not_found_hook').with_value('enroll')
        is_expected.to contain_ironic_inspector_config('processing/add_ports').with_value('all')
        is_expected.to contain_ironic_inspector_config('discovery/enroll_node_driver').with_value('pxe_ipmitool')
        is_expected.to contain_ironic_inspector_config('processing/always_store_ramdisk_logs').with_value(true)
        is_expected.to contain_ironic_inspector_config('port_physnet/cidr_map').with_value('192.168.20.0/24:physnet_a,2001:db8::/64:physnet_b')
      end

      it 'should contain file /etc/ironic-inspector/dnsmasq.conf' do
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with(
          'ensure'  => 'present',
          'require' => 'Anchor[ironic-inspector::config::begin]',
          'content' => /ipxe/,
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-boot=tag:ipxe,http:\/\/192.168.0.1:3816\/inspector.ipxe$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-range=192.168.0.100,192.168.0.120,10m$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^log-dhcp$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^log-queries$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-userclass=set:ipxe6,iPXE$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-option=tag:ipxe6,option6:bootfile-url,http:\/\/.*:3816\/inspector.ipxe$/
        )
        is_expected.not_to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-sequential-ip$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^log-facility=\/var\/log\/ironic-inspector\/dnsmasq.log$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-boot=tag:efi,tag:!ipxe,otherpxe.efi$/
        )
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-option=tag:efi6,tag:!ipxe6,option6:bootfile-url,tftp:\/\/.*\/otherpxe.efi$/
        )

      end
      it 'should contain file /var/www/httpboot/inspector.ipxe' do
        is_expected.to contain_file('/var/www/httpboot/inspector.ipxe').with(
          'owner'   => 'ironic-inspector',
          'group'   => 'ironic-inspector',
          'seltype' => 'httpd_sys_content_t',
          'ensure'  => 'present',
          'require' => 'Anchor[ironic-inspector::config::begin]',
          'content' => /ipxe/,
        )
        is_expected.to contain_file('/var/www/httpboot/inspector.ipxe').with_content(
            /kernel http:\/\/192.168.0.1:3816\/agent.kernel ipa-inspection-callback-url=http:\/\/192.168.0.1:5050\/v1\/continue ipa-inspection-collectors=default.* foo=bar || goto retry_boot/
        )
      end

      context 'when ipxe_timeout is set' do
        before :each do
          params.merge!(
            :ipxe_timeout => 30,
          )
        end

        it 'should contain file /var/www/httpboot/inspector.ipxe' do
          is_expected.to contain_file('/var/www/httpboot/inspector.ipxe').with_content(
              /kernel --timeout 30000/)
        end
      end

      context 'when using ipv6' do
        before :each do
          params.merge!(
            :listen_address     => 'fd00::1',
          )
        end

        it 'should contain file /var/www/httpboot/inspector.ipxe' do
          is_expected.to contain_file('/var/www/httpboot/inspector.ipxe').with_content(
            /kernel http:\/\/\[fd00::1\]:3816\/agent.kernel ipa-inspection-callback-url=http:\/\/\[fd00::1\]:5050\/v1\/continue ipa-inspection-collectors=default.* foo=bar || goto retry_boot/
          )
        end
      end
    end

    context 'when enabling ppc64le support' do
      let :pre_condition do
         "class { 'ironic::inspector::authtoken': password       => 'password', }"
      end

      before do
        params.merge!(
          :enable_ppc64le => true,
        )
      end

      it 'should contain file /etc/ironic-inspector/dnsmasq.conf' do
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-match=set:ppc64le,option:client-arch,14$/)
      end
      it 'should contain directory /tftpboot/ppc64le with selinux type tftpdir_t' do
        is_expected.to contain_file('/tftpboot/ppc64le').with(
          'owner'   => 'ironic-inspector',
          'group'   => 'ironic-inspector',
          'require' => 'Anchor[ironic-inspector::config::begin]',
          'ensure'  => 'directory',
          'seltype' => 'tftpdir_t',
        )
      end
      it 'should contain file /tftpboot/ppc64le/default' do
        is_expected.to contain_file('/tftpboot/ppc64le/default').with(
          'owner'   => 'ironic-inspector',
          'group'   => 'ironic-inspector',
          'seltype' => 'tftpdir_t',
          'ensure'  => 'present',
          'require' => 'Anchor[ironic-inspector::config::begin]',
          'content' => /default/,
        )
        is_expected.to contain_file('/tftpboot/ppc64le/default').with_content(
            /initrd=agent.ramdisk ipa-inspection-callback-url=http:\/\/192.168.0.1:5050\/v1\/continue ipa-inspection-collectors=default/
        )
      end
    end

    context 'when enabling ppc64le support with http default transport' do
      let :pre_condition do
         "class { 'ironic::inspector::authtoken': password       => 'password', }"
      end

      before do
        params.merge!(
          :enable_ppc64le        => true,
          :pxe_transfer_protocol => 'http',
        )
      end

      it 'should contain file /etc/ironic-inspector/dnsmasq.conf' do
        is_expected.to contain_file('/etc/ironic-inspector/dnsmasq.conf').with_content(
          /^dhcp-match=set:ppc64le,option:client-arch,14$/)
      end
      it 'should contain file /tftpboot/ppc64le/default' do
        is_expected.to contain_file('/tftpboot/ppc64le/default').with(
          'owner'   => 'ironic-inspector',
          'group'   => 'ironic-inspector',
          'seltype' => 'tftpdir_t',
          'ensure'  => 'present',
          'require' => 'Anchor[ironic-inspector::config::begin]',
          'content' => /default/,
        )
        is_expected.to contain_file('/tftpboot/ppc64le/default').with_content(
            /initrd=agent.ramdisk ipa-inspection-callback-url=http:\/\/192.168.0.1:5050\/v1\/continue ipa-inspection-collectors=default/
        )
      end
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let :platform_params do
        case facts[:os]['family']
        when 'Debian'
          { :inspector_package => 'ironic-inspector',
            :inspector_service => 'ironic-inspector' }
        when 'RedHat'
          { :inspector_package         => 'openstack-ironic-inspector',
            :inspector_dnsmasq_package => 'openstack-ironic-inspector-dnsmasq',
            :inspector_service         => 'ironic-inspector' }
        end
      end

      it_behaves_like 'ironic inspector'
    end
  end

end
