require 'spec_helper'

module NetsuiteIntegration
  describe Services::CountryService do

    subject { described_class }

    describe '#by_iso_country' do
      # Source:
      # https://system.netsuite.com/help/helpcenter/en_US/SchemaBrowser/platform/v2013_2_0/commonTypes.html#platformCommonTyp:Country
      it 'returns the funky NetSuite format' do
        expect(subject.by_iso_country('US')).to eq('_unitedStates')
        expect(subject.by_iso_country('BR')).to eq('_brazil')
        expect(subject.by_iso_country('DO')).to eq('_dominicanRepublic')
        expect(subject.by_iso_country('GB')).to eq('_unitedKingdomGB')
      end

      it 'defaults to united states' do
        expect(subject.by_iso_country('AREA51')).to eq('_unitedStates')
        expect(subject.by_iso_country(nil)).to eq('_unitedStates')
      end
    end

    describe '#to_iso_country' do
      # before adding more countries
      it 'contains many countries' do
        expect(subject.to_iso_country['_canada']).to eq('CA')
        expect(subject.to_iso_country['_unitedStates']).to eq('US')
        expect(subject.to_iso_country['_ireland']).to eq('IE')
        expect(subject.to_iso_country['_netherlands']).to eq('NL')
        expect(subject.to_iso_country['_unitedArabEmirates']).to eq('AE')
        expect(subject.to_iso_country['_newZealand']).to eq('NZ')
        expect(subject.to_iso_country['_kuwait']).to eq('KW')
        expect(subject.to_iso_country['_australia']).to eq('AU')
        expect(subject.to_iso_country['_southAfrica']).to eq('ZA')
        expect(subject.to_iso_country['_singapore']).to eq('SG')
        expect(subject.to_iso_country['_portugal']).to eq('PT')
        expect(subject.to_iso_country['_jordan']).to eq('JO')
        expect(subject.to_iso_country['_germany']).to eq('DE')
        expect(subject.to_iso_country['_pakistan']).to eq('PK')
        expect(subject.to_iso_country['_unitedKingdomGB']).to eq('GB')
        expect(subject.to_iso_country['_belgium']).to eq('BE')
        expect(subject.to_iso_country['_philippines']).to eq('PH')
        expect(subject.to_iso_country['_italy']).to eq('IT')
        expect(subject.to_iso_country['_malaysia']).to eq('MY')
        expect(subject.to_iso_country['_zambia']).to eq('ZM')
        expect(subject.to_iso_country['_india']).to eq('IN')
        expect(subject.to_iso_country['_malta']).to eq('MT')
        expect(subject.to_iso_country['_mexico']).to eq('MX')
        expect(subject.to_iso_country['_poland']).to eq('PL')
        expect(subject.to_iso_country['_trinidadAndTobago']).to eq('TT')
        expect(subject.to_iso_country['_france']).to eq('FR')
        expect(subject.to_iso_country['_nigeria']).to eq('NG')
        expect(subject.to_iso_country['_bruneiDarussalam']).to eq('BN')
        expect(subject.to_iso_country['_hongKong']).to eq('HK')
        expect(subject.to_iso_country['_guam']).to eq('GU')
        expect(subject.to_iso_country['_jamaica']).to eq('JM')
        expect(subject.to_iso_country['_virginIslandsUSA']).to eq('VI')
        expect(subject.to_iso_country['_croatiaHrvatska']).to eq('HR')
        expect(subject.to_iso_country['_spain']).to eq('ES')
      end
    end
  end
end

