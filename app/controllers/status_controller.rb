# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    # OpenSSL.fips_mode=true
    # render json "{}"
    render 'index'
  end
end
