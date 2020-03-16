# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    OpenSSL.fips_mode=true
    render json: {
       # error: {
       #     OPENSSL_VERSION: OpenSSL::OPENSSL_VERSION,
       #     OPENSSL_LIBRARY_VERSION: OpenSSL::OPENSSL_LIBRARY_VERSION
       # }.compact
       }
    # }, status: :not_found
    # render 'index'
  end

end
