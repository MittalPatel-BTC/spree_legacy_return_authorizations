Spree::Admin::NavigationHelper.module_eval do
  prepend Spree::Admin::AdditionalNavigationHelper
  # alias_method_chain :tab, :legacy_return_authorizations
end
