#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
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
# ironic::client
#
# Manages the ironic client package on systems
#
# === Parameters:
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
#
class ironic::client (
  $package_ensure = present
) {

  include ironic::deps
  include ironic::params

  package { 'python-ironicclient':
    ensure => $package_ensure,
    name   => $::ironic::params::client_package,
    tag    => ['openstack', 'ironic-support-package'],
  }

  include openstacklib::openstackclient

}
