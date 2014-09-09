module NetsuiteIntegration
  module Services
    class StateService
      class << self
        def by_state_name(state_name)
          # NOTE Assume that a valid two digit US state was given
          return state_name if state_name.to_s.size == 2

          if abbr = @@states[state_name.to_s]
            abbr
          else
            all_states[state_name] || state_name
          end
        end

        @@states = JSON.parse IO.read(File.join(__dir__, "../../netsuite/states.json"))

        # NOTE Ideally this should never run live. All possible states should
        # be in netsuite/states.json
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
