# A category as associated with a prefix.
#
# I am trying very hard not to perpetuate the term "rule" for prefix-category link.
# Our essential concern is which categories are associated with which prefixes.
#
# A Prefix object can return its categories, however, in order to get the confidence value of the association,
# we cannot represent this simply with a Category class.
# So this is a class which aggregates Category, but which holds data about the prefix-category association itself.
class Wbrs::AssociatedCategory
  attr_reader :category_id, :confidence, :is_active

  alias_method(:id, :category_id)

  def initialize(category_id:, confidence:, is_active:)
    @category_id = category_id
    @confidence = confidence.to_f
    @is_active = (1 == is_active)
  end

  def category
    @category ||= Wbrs::Category.find(category_id)
  end

  %i{desc_long descr mnem}.each do |method_sym|
    define_method(method_sym) {category.send(method_sym)}
  end
end
