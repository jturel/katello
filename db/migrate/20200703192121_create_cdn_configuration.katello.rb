class CreateCdnConfiguration < ActiveRecord::Migration[6.0]
  def change
    create_table :katello_cdn_configurations do |t|
      t.integer :organization_id
      t.integer :ssl_ca_credential_id
      t.integer :ssl_cert_credential_id
      t.integer :ssl_key_credential_id
      t.string :url
    end
  end
end
