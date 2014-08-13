require 'httparty'
require 'date'
require 'awesome_print'
require 'redis'
require 'json'

WUFOO_AUTH = {
  username: ENV["WUFOO_USERNAME"],
  password: ENV["WUFOO_PASSWORD"],
}
FORM_URL = "https://theaustinstone.wufoo.com/api/v3/forms/far-more-involve/entries.json"
PAGE_SIZE = 100

redis = Redis.new(url: ENV["REDISCLOUD_URL"])
CACHE_PREFIX = "wufoo_response_page_"

WEEKS = 6 # show signups for the last six weeks, rolling
SECONDS_IN_A_WEEK = 60 * 60 * 24 * 7

# get the JSON entries for the given page of a form. pages are always of size
# PAGE_SIZE.
def get_entries(page_number)
  key = CACHE_PREFIX + page_number.to_s
  cached_response = redis.get(key)

  # return the cached response if it's already in redis
  if cached_response != nil
    return JSON.parse(cached_response)
  end

  # otherwise, fetch and cache it
  resp = HTTParty.get(FORM_URL, query: {
    pageSize: PAGE_SIZE,
    pageStart: PAGE_SIZE * page_number,
    basic_auth: WUFOO_AUTH,
  })

  # make sure we got a good response
  throw "Wufoo response error: #{resp.code}" if resp.code != 200

  # cache the response value
  redis.set(key, JSON.generate(rest))

  # if the page was not full, expire the key after a short time so we'll
  # re-fetch the page in the future to check for new entries
  if (resp["Entries"] || []).length < PAGE_SIZE
    redis.expire(key, 60)
  end

  resp
end

SCHEDULER.every '1m', :first_in => 0 do
  STDERR.puts "======= Wufoo Fetch!"
  pages = 0
  page_start = 0
  entries = []

  while true
    STDERR.puts "Fetching from EntryId #{page_start}."
    pages += 1
    resp = HTTParty.get("https://elbenshira.wufoo.com/api/v3/forms/stone-test/entries.json?pageSize=100&pageStart=#{page_start}",
                        basic_auth: WUFOO_AUTH)

    page_entries = resp["Entries"] || []
    if page_entries.length > 0
      STDERR.puts "Got #{page_entries.count} items."
      page_start = page_entries.last["EntryId"].to_i
      entries += page_entries
    else
      break
    end
  end

  STDERR.puts "======= Fetched #{pages} pages, #{entries.count} entries."

  # Total signups over weeks
  this_week = Time.now.to_i / SECONDS_IN_A_WEEK
  first_week = this_week - WEEKS
  weekly_counts = [0] * (WEEKS + 1)

  campus_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }
  next_step_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }

  entries.each do |entry|
    # Weekly counts
    week = DateTime.parse(entry["DateCreated"]).to_time.to_i / SECONDS_IN_A_WEEK
    idx = week - first_week
    weekly_counts[idx] += 1

    # Campus leaderboard
    campus = entry["Field5"]
    if !campus.nil? && campus.length > 0
      campus_counts[campus][:value] += 1
    end

    # Next step counts
    ["Field6", "Field7", "Field8", "Field9"].each do |k|
      next_step = entry[k]
      if !next_step.nil? && !next_step.empty?
        next_step_counts[next_step][:value] += 1
      end
    end
  end

  points = []
  weekly_counts.each_with_index { |count, idx| points << {x: idx, y: count} }

  # Send events
  send_event('farmore-campus-leaderboard', items: campus_counts.values)
  send_event('farmore-next-steps', items: next_step_counts.values)
  send_event('signup-total', value: entries.count)
  send_event('farmore-weekly', points: points)
end
