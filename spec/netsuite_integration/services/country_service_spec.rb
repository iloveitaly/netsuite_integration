require 'spec_helper'

module NetsuiteIntegration
  describe Services::CountryService do

    subject { described_class }

    # Source:
    # https://system.netsuite.com/help/helpcenter/en_US/SchemaBrowser/platform/v2013_2_0/commonTypes.html#platformCommonTyp:Country
    it 'returns the funky NetSuite format' do
      expect(subject.by_iso_country('US')).to eq('_unitedStates')
      expect(subject.by_iso_country('BR')).to eq('_brazil')
      expect(subject.by_iso_country('DO')).to eq('_dominicanRepublic')
    end

    it 'defaults to united states' do
      expect(subject.by_iso_country('AREA51')).to eq('_unitedStates')
    end
  end
end

