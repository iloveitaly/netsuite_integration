require 'spec_helper'

module NetsuiteIntegration
  describe Services::StateService do
    include_context "connect to netsuite"

    subject { described_class }

    it 'returns the correct abbreviation' do
      expect(subject.by_state_name('Maryland')).to eq('MD')
    end

    it 'returns the state if its not found' do
      VCR.use_cassette "states/others" do
        expect(subject.by_state_name('Sao Paulo')).to eq('Sao Paulo')
      end
    end

    it 'fetches non us states' do
      expect(subject.by_state_name('Guanajuato')).to eq('GTO')
    end
  end
end
