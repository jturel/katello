module Katello
  class CdnConfiguration < Katello::Model
    belongs_to :organization
    belongs_to :ssl_ca_credential, :class_name => "Katello::GpgKey"
    belongs_to :ssl_cert_credential, :class_name => "Katello::GpgKey"
    belongs_to :ssl_key_credential, :class_name => "Katello::GpgKey"
  end
end
