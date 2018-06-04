class Wbrs::Rule < Wbrs::Base

  def self.get(categories: nil)
    response = post(path: '/v1/cat/rules/get', body: {"categories": categories })

    Rails.logger.debug(">>> Wbrs::Rule.get #{response.inspect}")
  end
end
