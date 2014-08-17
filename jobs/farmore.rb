require 'httparty'
require 'date'
require 'awesome_print'
require 'redis'
require 'json'

WUFOO_AUTH = {
  username: ENV["WUFOO_KEY"],
  password: "",
}
FORM_URL = "https://theaustinstone.wufoo.com/api/v3/forms/far-more-involve/entries.json"
PAGE_SIZE = 100

REDIS = Redis.new(url: ENV["REDISCLOUD_URL"])
CACHE_PREFIX = "wufoo_response_page_"

WEEKS = 6 # show signups for the last six weeks, rolling
SECONDS_IN_A_WEEK = 60 * 60 * 24 * 7

# get the JSON entries for the given page of a form. pages are always of size
# PAGE_SIZE. returns an array of entries in id-order.
def get_entries_by_page(page_number)
  key = CACHE_PREFIX + page_number.to_s
  cached_response = REDIS.get(key)

  # return the cached response if it's already in redis
  if cached_response != nil
    return JSON.parse(cached_response)
  end

  # otherwise, fetch and cache it
  resp = HTTParty.get(FORM_URL, basic_auth: WUFOO_AUTH, query: {
    pageSize: PAGE_SIZE,
    pageStart: PAGE_SIZE * page_number,
  })

  # make sure we got a good response
  throw "Wufoo response error: #{resp.code}" if resp.code != 200

  # cache the response value
  REDIS.set(key, JSON.generate(resp))

  # if the page was not full, expire the key after a short time so we'll
  # re-fetch the page in the future to check for new entries
  entries = resp["Entries"] || []
  if entries.length < PAGE_SIZE
    REDIS.expire(key, 60)
  else
    # expire full pages after a while too, to ensure that we have relatively
    # up-to-date data at all times.
    REDIS.expire(key, 60 * 60 * 3)
  end

  entries
end

# returns all the entries in the form
def get_all_entries()
  entries = []

  page_number = 0
  while true
    page_entries = get_entries_by_page(page_number)

    # give up once we get a non-full page
    break if page_entries.length < PAGE_SIZE

    # add the entries to our collection and continue to the next page
    entries.concat(page_entries)
    page_number += 1
  end

  entries
end

# Wufoo's API limit is 10000 requests/day. with 1440 minutes in a day, polling
# every five minutes lets us run 34 dashboards simultaneously without hitting
# the limit.
SCHEDULER.every '5m', :first_in => 0 do

  # TODO: make this work with the form format! it's currently broken :(

  # Total signups over weeks
  this_week = Time.now.to_i / SECONDS_IN_A_WEEK
  first_week = this_week - WEEKS
  weekly_counts = [0] * (WEEKS + 1)

  campus_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }
  next_step_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }

  entries = get_all_entries()
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
