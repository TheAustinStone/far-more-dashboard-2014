require 'httparty'

auth = {
  username: "POT5-R55R-95L6-9L1D",
  password: "foo",
}


CAMPUSES = ["St John AM", "Downtown PM", "West"]
next_steps = ["Missional community", "Service Team", "Coffee runner", "Litter picker upper",]

def name
  "Bob #{rand}"
end

def next_step_chance(next_step)
  if rand < 0.3
    next_step
  end
end

def fake
  {
    # "UpdatedBy" => nil,
    # "DateUpdated" => "",
    # "CreatedBy" => "public",
    # "DateCreated" => "2014-08-09 11:58:18",
    # "EntryId" => "2",
    "Field1" => name,
    "Field4" => "sue1@example.com",
    "Field5" => CAMPUSES.sample,
    "Field6" => next_step_chance("Missional community"),
    "Field7" => next_step_chance("Service Team"),
    "Field8" => next_step_chance("Coffee runner"),
    "Field9" => next_step_chance("Litter picker upper")
  }
end

100.times do
  resp = HTTParty.post("https://elbenshira.wufoo.com/api/v3/forms/stone-test/entries.json?pageSize=100",
                       body: fake,
                       basic_auth: auth)
  ap resp
  sleep 1
end
