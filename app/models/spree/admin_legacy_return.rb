module Spree
  module AdminLegacyReturn
    def awaiting_return_with_legacy_return_authorizations?
      awaiting_return_without_legacy_return_authorizations? ||
      legacy_return_authorizations.any? { |legacy_return_authorization| legacy_return_authorization.authorized? }
    end
  end
end
