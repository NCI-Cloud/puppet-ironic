# == Class: ironic::healthcheck
#
# Configure oslo_middleware options in healthcheck section
#
# == Params
#
# [*enabled*]
#   (Optional) Enable the healthcheck endpoint at /healthcheck.
#   Defaults to $facts['os_service_default']
#
# [*detailed*]
#   (Optional) Show more detailed information as part of the response.
#   Defaults to $facts['os_service_default']
#
# [*backends*]
#   (Optional) Additional backends that can perform health checks and report
#   that information back as part of a request.
#   Defaults to $facts['os_service_default']
#
# [*disable_by_file_path*]
#   (Optional) Check the presence of a file to determine if an application
#   is running on a port.
#   Defaults to $facts['os_service_default']
#
# [*disable_by_file_paths*]
#   (Optional) Check the presence of a file to determine if an application
#   is running on a port. Expects a "port:path" list of strings.
#   Defaults to $facts['os_service_default']
#
class ironic::healthcheck (
  $enabled               = $facts['os_service_default'],
  $detailed              = $facts['os_service_default'],
  $backends              = $facts['os_service_default'],
  $disable_by_file_path  = $facts['os_service_default'],
  $disable_by_file_paths = $facts['os_service_default'],
) {

  include ironic::deps

  ironic_config {
    'healthcheck/enabled': value => $enabled;
  }

  oslo::healthcheck { 'ironic_config':
    detailed              => $detailed,
    backends              => $backends,
    disable_by_file_path  => $disable_by_file_path,
    disable_by_file_paths => $disable_by_file_paths,
  }
}
