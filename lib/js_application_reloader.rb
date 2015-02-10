require "js_application_reloader/version"
require "js_application_reloader/controller_extensions"

module JsApplicationReloader

  # Can override these via their setters in config/initializers/js_application_reloader.rb
  @async_js_project = false
  @token = nil
  @token_header_name = "X-Js-Application-Reloader-Current-Token"
  @status_header_name = "X-Js-Application-Reloader-Status"
  @reload_required_http_status = 200
  @application_name = 'this application'
  @redirect_url = '/users/sign_in'

  class << self
    attr_accessor :async_js_project
    attr_accessor :token
    attr_accessor :token_header_name
    attr_accessor :status_header_name
    attr_accessor :reload_required_http_status
    attr_accessor :application_name
    attr_accessor :redirect_url
  end

  # Nice configuration is a small twist on http://robots.thoughtbot.com/mygem-configure-block. Thanks!

  def self.configure
    yield(self)
  end

  # Must be injected into ERB template using raw
  # TODO: Option to limit fields sent to the client for lightness
  def self.inject_script
    <<-EOF
      <script type="text/javascript">
        JsApplicationReloader = {
          token: '#{JsApplicationReloader.token}',
          tokenHeaderName: '#{JsApplicationReloader.token_header_name}',
          statusHeaderName: '#{JsApplicationReloader.status_header_name}',
          reloadRequiredHttpStatus: '#{JsApplicationReloader.reload_required_http_status}',
          applicationName: '#{JsApplicationReloader.application_name}',
          redirectUrl: '#{JsApplicationReloader.redirect_url}'
        };

        // -- Define Expiration check
        JsApplicationReloader.isTokenExpired = function(xhr) {
          return (xhr.status == JsApplicationReloader.reloadRequiredHttpStatus && (xhr.getResponseHeader(JsApplicationReloader.statusHeaderName) === 'token_expired'));
        };

        #{handle_reloader_token_expiration_on_client}

        #{JsApplicationReloader.non_async_js_request_script unless JsApplicationReloader.async_js_project}
      </script>
    EOF
  end

  # Expiration handler (you can customize this)
  def self.handle_reloader_token_expiration_on_client
    <<-EOF
        JsApplicationReloader.handleTokenExpiration = function(xhr) {
          $('body').html(xhr.responseText); // Display the HTML returned by xhr.responseText as you see fit
          return false;
        };
    EOF
  end

  # For non-async Javascript projects
  def self.non_async_js_request_script
    <<-EOF
      $(document).ready(function() {
          $(document).ajaxSend(function(event, request) {
              if (JsApplicationReloader && JsApplicationReloader.token) {
                  request.setRequestHeader('#{JsApplicationReloader.token_header_name}', JsApplicationReloader.token);
             }
          });
      });
    EOF
  end
end
