require 'digest'
require 'net/http'
require 'uri'
class SbApiController < ApplicationController
  before_action :referrer_check

  def safe_json(json)
    begin
      JSON.parse(json)
    rescue
      JSON.parse('{}')
    end
  end

  def query_lookup()
    response = safe_json(SbApi.query_lookup(sb_api_params))
    render json: response, status: :created
  end

  private

  def sb_api_params
    params.permit(:query, :query_entry, :query_type, :query_string, :hostname, :offset, :order, :full_response, query_entry: [:duration, :dur_measure,
                                        :result_measure, :sender_type,
                                        :limit, :sources ])
  end

  def referrer_check
    # we may want to be override this check while in development mode
    unless request.referrer || Rails.env == "development"
      render json: "Nope", status: :created
    end
  end
end
