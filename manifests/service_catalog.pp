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
# == Class: ironic::service_catalog
#
# [*auth_type*]
#   The authentication plugin to use when connecting to the service catalog.
#   Defaults to 'password'
#
# [*auth_url*]
#   The address of the keystone api endpoint.
#   Defaults to $facts['os_service_default']
#
# [*project_name*]
#   The Keystone project name.
#   Defaults to 'services'
#
# [*username*]
#   The admin username for ironic to connect to the service catalog.
#   Defaults to 'ironic'.
#
# [*password*]
#   The admin password for ironic to connect to the service catalog.
#   Defaults to $facts['os_service_default']
#
# [*user_domain_name*]
#   The name of user's domain (required for Identity V3).
#   Defaults to 'Default'
#
# [*project_domain_name*]
#   The name of project's domain (required for Identity V3).
#   Defaults to 'Default'
#
# [*system_scope*]
#   (Optional) Scope for system operations
#   Defaults to $facts['os_service_default']
#
# [*region_name*]
#   (optional) Region name for accessing Keystone catalog
#   through the OpenStack Identity service.
#   Defaults to $facts['os_service_default']
#
# [*endpoint_override*]
#   The endpoint URL for requests for this client
#   Defaults to $facts['os_service_default']
#
class ironic::service_catalog (
  $auth_type           = 'password',
  $auth_url            = $facts['os_service_default'],
  $project_name        = 'services',
  $username            = 'ironic',
  $password            = $facts['os_service_default'],
  $user_domain_name    = 'Default',
  $project_domain_name = 'Default',
  $system_scope        = $facts['os_service_default'],
  $region_name         = $facts['os_service_default'],
  $endpoint_override   = $facts['os_service_default'],
) {

  include ironic::deps

  if is_service_default($system_scope) {
    $project_name_real = $project_name
    $project_domain_name_real = $project_domain_name
  } else {
    $project_name_real = $facts['os_service_default']
    $project_domain_name_real = $facts['os_service_default']
  }

  ironic_config {
    'service_catalog/auth_type':           value => $auth_type;
    'service_catalog/username':            value => $username;
    'service_catalog/password':            value => $password, secret => true;
    'service_catalog/auth_url':            value => $auth_url;
    'service_catalog/project_name':        value => $project_name_real;
    'service_catalog/user_domain_name':    value => $user_domain_name;
    'service_catalog/project_domain_name': value => $project_domain_name_real;
    'service_catalog/system_scope':        value => $system_scope;
    'service_catalog/region_name':         value => $region_name;
    'service_catalog/endpoint_override':   value => $endpoint_override;
  }
}
