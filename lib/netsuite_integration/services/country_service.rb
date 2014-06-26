module NetsuiteIntegration
  module Services
    class CountryService
      class << self
        def to_iso_country
          {
            '_canada' => 'CA',
            '_unitedStates' => 'US',
            '_ireland' => 'IE',
            '_netherlands' => 'NL',
            '_unitedArabEmirates' => 'AE',
            '_newZealand' => 'NZ',
            '_kuwait' => 'KW',
            '_australia' => 'AU',
            '_southAfrica' => 'ZA',
            '_singapore' => 'SG',
            '_portugal' => 'PT',
            '_jordan' => 'JO',
            '_germany' => 'DE',
            '_pakistan' => 'PK',
            '_unitedKingdomGB' => 'GB',
            '_belgium' => 'BE',
            '_philippines' => 'PH',
            '_italy' => 'IT',
            '_malaysia' => 'MY',
            '_zambia' => 'ZM',
            '_india' => 'IN',
            '_malta' => 'ML',
            '_mexico' => 'MX',
            '_poland' => 'PL',
            '_trinidadAndTobago' => 'TT',
            '_france' => 'FR',
            '_nigeria' => 'NG',
            '_bruneiDarussalam' => 'BN',
            '_hongKong' => 'HK',
            '_guam' => 'GU',
            '_jamaica' => 'JAM',
            '_virginIslandsUSA' => 'VI',
            '_croatiaHrvatska' => 'HR',
            '_spain' => 'ES'
          }
        end

        def by_iso_country(iso_country)
          country = @@countries.fetch(iso_country, "United States")

          names = country.split(" ")
          names.first.downcase!

          "_#{names.join}"
        end

        # NetSuite Format Source:
        # https://system.netsuite.com/help/helpcenter/en_US/SchemaBrowser/platform/v2013_2_0/commonTypes.html#platformCommonTyp:Country

        # Taken from https://github.com/brunobuccolo/spree/blob/master/core/db/default/spree/countries.rb
        @@countries = {"TD"=>"Chad", "FO"=>"Faroe Islands", "IN"=>"India", "NI"=>"Nicaragua", "LC"=>"Saint Lucia", "FJ"=>"Fiji", "ID"=>"Indonesia", "NE"=>"Niger", "PM"=>"Saint Pierre and Miquelon", "FI"=>"Finland", "NG"=>"Nigeria", "VC"=>"Saint Vincent and the Grenadines", "FR"=>"France", "IR"=>"Iran, Islamic Republic of", "NU"=>"Niue", "WS"=>"Samoa", "GF"=>"French Guiana", "IQ"=>"Iraq", "SM"=>"San Marino", "IE"=>"Ireland", "ST"=>"Sao Tome and Principe", "IL"=>"Israel", "SA"=>"Saudi Arabia", "IT"=>"Italy", "SN"=>"Senegal", "JM"=>"Jamaica", "JP"=>"Japan", "JO"=>"Jordan", "BE"=>"Belgium", "BZ"=>"Belize", "KZ"=>"Kazakhstan", "UG"=>"Uganda", "BJ"=>"Benin", "KE"=>"Kenya", "UA"=>"Ukraine", "BM"=>"Bermuda", "KI"=>"Kiribati", "MX"=>"Mexico", "AE"=>"United Arab Emirates", "BT"=>"Bhutan", "CU"=>"Cuba", "KP"=>"North Korea", "FM"=>"Micronesia, Federated States of", "GB"=>"United Kingdom", "BO"=>"Bolivia", "CY"=>"Cyprus", "KR"=>"South Korea", "MD"=>"Moldova, Republic of", "US"=>"United States", "BA"=>"Bosnia and Herzegovina", "CZ"=>"Czech Republic", "KW"=>"Kuwait", "MC"=>"Monaco", "UY"=>"Uruguay", "BW"=>"Botswana", "DK"=>"Denmark", "GP"=>"Guadeloupe", "KG"=>"Kyrgyzstan", "MN"=>"Mongolia", "PH"=>"Philippines", "BR"=>"Brazil", "DJ"=>"Djibouti", "GU"=>"Guam", "LA"=>"Lao People's Democratic Republic", "MS"=>"Montserrat", "PN"=>"Pitcairn", "UZ"=>"Uzbekistan", "BN"=>"Brunei Darussalam", "DM"=>"Dominica", "GT"=>"Guatemala", "MA"=>"Morocco", "PL"=>"Poland", "VU"=>"Vanuatu", "DO"=>"Dominican Republic", "MZ"=>"Mozambique", "PT"=>"Portugal", "SD"=>"Sudan", "VE"=>"Venezuela", "EC"=>"Ecuador", "GN"=>"Guinea", "MM"=>"Myanmar", "PR"=>"Puerto Rico", "SR"=>"Suriname", "VN"=>"Viet Nam", "EG"=>"Egypt", "GW"=>"Guinea-Bissau", "NA"=>"Namibia", "QA"=>"Qatar", "SJ"=>"Svalbard and Jan Mayen", "SV"=>"El Salvador", "GY"=>"Guyana", "RE"=>"Reunion", "HT"=>"Haiti", "RO"=>"Romania", "SZ"=>"Swaziland", "VA"=>"Holy See (Vatican City State)", "RU"=>"Russian Federation", "SE"=>"Sweden", "HN"=>"Honduras", "RW"=>"Rwanda", "CH"=>"Switzerland", "HK"=>"Hong Kong", "SY"=>"Syrian Arab Republic", "TW"=>"Taiwan", "TJ"=>"Tajikistan", "TZ"=>"Tanzania, United Republic of", "AM"=>"Armenia", "AW"=>"Aruba", "AU"=>"Australia", "TH"=>"Thailand", "AT"=>"Austria", "MG"=>"Madagascar", "TG"=>"Togo", "AZ"=>"Azerbaijan", "CL"=>"Chile", "MW"=>"Malawi", "TK"=>"Tokelau", "BS"=>"Bahamas", "CN"=>"China", "MY"=>"Malaysia", "TO"=>"Tonga", "BH"=>"Bahrain", "CO"=>"Colombia", "MV"=>"Maldives", "TT"=>"Trinidad and Tobago", "BD"=>"Bangladesh", "KM"=>"Comoros", "PF"=>"French Polynesia", "ML"=>"Mali", "NF"=>"Norfolk Island", "TN"=>"Tunisia", "BB"=>"Barbados", "CG"=>"Congo", "GA"=>"Gabon", "MT"=>"Malta", "MP"=>"Northern Mariana Islands", "TR"=>"Turkey", "CD"=>"Congo, the Democratic Republic of the", "MH"=>"Marshall Islands", "NO"=>"Norway", "TM"=>"Turkmenistan", "BY"=>"Belarus", "CK"=>"Cook Islands", "GM"=>"Gambia", "MQ"=>"Martinique", "OM"=>"Oman", "SC"=>"Seychelles", "TC"=>"Turks and Caicos Islands", "GE"=>"Georgia", "MR"=>"Mauritania", "PK"=>"Pakistan", "SL"=>"Sierra Leone", "TV"=>"Tuvalu", "CR"=>"Costa Rica", "DE"=>"Germany", "MU"=>"Mauritius", "PW"=>"Palau", "CI"=>"Cote D'Ivoire", "PA"=>"Panama", "SG"=>"Singapore", "HR"=>"Croatia", "GH"=>"Ghana", "PG"=>"Papua New Guinea", "SK"=>"Slovakia", "GI"=>"Gibraltar", "PY"=>"Paraguay", "SI"=>"Slovenia", "GR"=>"Greece", "PE"=>"Peru", "SB"=>"Solomon Islands", "GL"=>"Greenland", "SO"=>"Somalia", "GD"=>"Grenada", "ZA"=>"South Africa", "ES"=>"Spain", "LK"=>"Sri Lanka", "AF"=>"Afghanistan", "AL"=>"Albania", "DZ"=>"Algeria", "LV"=>"Latvia", "AS"=>"American Samoa", "BG"=>"Bulgaria", "LB"=>"Lebanon", "AD"=>"Andorra", "BF"=>"Burkina Faso", "LS"=>"Lesotho", "AO"=>"Angola", "BI"=>"Burundi", "LR"=>"Liberia", "VG"=>"Virgin Islands, British", "AI"=>"Anguilla", "KH"=>"Cambodia", "GQ"=>"Equatorial Guinea", "LY"=>"Libyan Arab Jamahiriya", "NR"=>"Nauru", "VI"=>"Virgin Islands, U.S.", "AG"=>"Antigua and Barbuda", "CM"=>"Cameroon", "LI"=>"Liechtenstein", "NP"=>"Nepal", "WF"=>"Wallis and Futuna", "EH"=>"Western Sahara", "AR"=>"Argentina", "CA"=>"Canada", "ER"=>"Eritrea", "LT"=>"Lithuania", "NL"=>"Netherlands", "YE"=>"Yemen", "CV"=>"Cape Verde", "EE"=>"Estonia", "LU"=>"Luxembourg", "AN"=>"Netherlands Antilles", "SH"=>"Saint Helena", "ZM"=>"Zambia", "KY"=>"Cayman Islands", "ET"=>"Ethiopia", "HU"=>"Hungary", "MO"=>"Macao", "NC"=>"New Caledonia", "ZW"=>"Zimbabwe", "CF"=>"Central African Republic", "FK"=>"Falkland Islands (Malvinas)", "IS"=>"Iceland", "MK"=>"Macedonia", "NZ"=>"New Zealand", "KN"=>"Saint Kitts and Nevis", "RS"=>"Serbia"}
      end
    end
  end
end
