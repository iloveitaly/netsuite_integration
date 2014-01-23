require 'spec_helper'

module NetsuiteIntegration
  describe Services::StateService do

    subject { described_class }

    it 'returns the correct abbreviation' do
      expect(subject.by_state_name('Maryland')).to eq('MD')
    end

    it 'returns the state if its not found' do
      expect(subject.by_state_name('Sao Paulo')).to eq('Sao Paulo')
    end
  end
end

