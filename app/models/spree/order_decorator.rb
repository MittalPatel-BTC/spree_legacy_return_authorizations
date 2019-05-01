Spree::Order.class_eval do
  has_many :legacy_return_authorizations, dependent: :destroy

  prepend Spree::AdminLegacyReturn

  #alias_method_chain :awaiting_return?, :legacy_return_authorizations
end
