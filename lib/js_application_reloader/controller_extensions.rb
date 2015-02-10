module JsApplicationReloader
  module ControllerExtensions

    def self.included(base)
      base.before_filter :handle_js_application_reloader_token_expiration
    end

    def handle_js_application_reloader_token_expiration
      # Note: we do a string comparision to avoid 232323 not matching "232323" mistakes
      if request.headers[JsApplicationReloader.token_header_name] && (request.headers[JsApplicationReloader.token_header_name].to_s != JsApplicationReloader.token.to_s)
        response.headers[JsApplicationReloader.status_header_name] = 'token_expired'
        render_js_application_reloader_expiration
      end
    end

    # override me in your ApplicationController to customize what gets
    # sent back to the client on token expiration
    def render_js_application_reloader_expiration
        render :text => "A new version of #{JsApplicationReloader.application_name} is available. Please click <a href='#{JsApplicationReloader.redirect_url}'>here</a> to load it.", :status => JsApplicationReloader.reload_required_http_status
    end

  end
end
