# typed: false
# frozen_string_literal: true

require "spec_helper"

describe UpdateDomainWorker do
  describe "#perform" do
    it "finds the domain and updates its metadata" do
      domain = create(:domain, name: "morph.io")

      # Mock RestClient resource response
      resource = instance_double(RestClient::Resource)
      html_content = "<html><head><title>\nmorph.io   </title><meta name='Description' content='Get structured data out of the web.'></head></html>"
      allow(RestClient::Resource).to receive(:new)
        .with("http://morph.io", verify_ssl: OpenSSL::SSL::VERIFY_NONE)
        .and_return(resource)
      allow(resource).to receive(:get).and_return(html_content)

      expect { described_class.new.perform(domain.id) }.to change { domain.reload.meta }.from(nil).to("Get structured data out of the web.")
                                                                                        .and change { domain.reload.title }.from(nil).to("morph.io")
    end
  end
end
