class Webcat::EntryVerdictChecker
  attr_reader :domain, :categories

  def initialize(domain, categories)
    @domain = domain
    @categories = categories
  end

  def check
    verdict_pass = true
    verdict_reasons = []

    all_cats = Wbrs::Category.all
    cats_by_short = []

    categories.each do |cat_id|
      all_cats.each do |base_cat|
        cats_by_short << base_cat.mnem if base_cat.category_id == cat_id
      end
    end

    cats_by_short.each do |category|
      result = JSON.parse(Webcat::GuardRails.verdict_for_entry(domain, category).body)
      verdict_data = result[domain]

      next if verdict_data['color'] == Webcat::GuardRails::PASS

      verdict_pass = false
      verdict_reason = "|#{category} = #{verdict_data['color']}:"
      verdict_reason += "#{verdict_data["why"]["reason"].pluck("reason").join(",")} \n" rescue "no reasons data\n"
      verdict_reasons << verdict_reason
    end

    {
      verdict_pass: verdict_pass,
      verdict_reasons: verdict_reasons
    }
  rescue Exception => e
    Rails.logger.error(e.message)
    {
      verdict_pass: false,
      verdict_reasons: verdict_reasons << 'there was an api call failure, erring to manager review'
    }
  end
end
