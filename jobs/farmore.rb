require 'httparty'
require 'awesome_print'

auth = {
  username: "POT5-R55R-95L6-9L1D",
  password: "foo",
}

SCHEDULER.every '10s' do
  resp = HTTParty.get("https://elbenshira.wufoo.com/api/v3/forms/stone-test/fields.json",
                      basic_auth: auth)
  ap "!!!!!!!!!!!!!"
  ap resp
  ap "!!!!!!!!!!!!!"
  send_event('synergy', value: resp["Fields"].count)
end
