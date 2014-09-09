module NetsuiteIntegration
  module Services
    class StateService
      class << self
        def by_state_name(state_name)
          # NOTE Assume that a valid two digit US state was given
          return state_name if state_name.to_s.size == 2

          if abbr = @@states[state_name]
            abbr
          else
            all_states[state_name] || state_name
          end
        end

        @@states = {
          "Alabama" => "AL",
          "Alaska" => "AK",
          "Arizona" => "AZ",
          "Arkansas" => "AR",
          "California" => "CA",
          "Colorado" => "CO",
          "Connecticut" => "CT",
          "District of Columbia" => "DC",
          "Delaware" => "DE",
          "Florida" => "FL",
          "Georgia" => "GA",
          "Hawaii" => "HI",
          "Idaho" => "ID",
          "Illinois" => "IL",
          "Indiana" => "IN",
          "Iowa" => "IA",
          "Kansas" => "KS",
          "Kentucky" => "KY",
          "Louisiana" => "LA",
          "Maine" => "ME",
          "Maryland" => "MD",
          "Massachusetts" => "MA",
          "Michigan" => "MI",
          "Minnesota" => "MN",
          "Mississippi" => "MS",
          "Missouri" => "MO",
          "Montana" => "MT",
          "Nebraska" => "NE",
          "Nevada" => "NV",
          "New Hampshire" => "NH",
          "New Jersey" => "NJ",
          "New Mexico" => "NM",
          "New York" => "NY",
          "North Carolina" => "NC",
          "North Dakota" => "ND",
          "Ohio" => "OH",
          "Oklahoma" => "OK",
          "Oregon" => "OR",
          "Pennsylvania" => "PA",
          "Rhode Island" => "RI",
          "South Carolina" => "SC",
          "South Dakota" => "SD",
          "Tennessee" => "TN",
          "Texas" => "TX",
          "Utah" => "UT",
          "Vermont" => "VT",
          "Virginia" => "VA",
          "Washington" => "WA",
          "West Virginia" => "WV",
          "Wisconsin" => "WI",
          "Wyoming" => "WY"
        }

        def all_states
          states = NetSuite::Configuration.connection.call(:get_all, message: {
            'platformCore:record' => {
              '@recordType' => 'state'
            }
          })

          records = states.to_array.first[:get_all_response][:get_all_result][:record_list][:record]
          records.inject({}) do |collection, r|
            collection[r[:full_name]] = r[:shortname]
            collection
          end
        end
      end
    end
  end
end
