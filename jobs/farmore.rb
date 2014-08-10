require 'httparty'
require 'date'
require 'awesome_print'

auth = {
  username: "WRXE-5Y2U-50JV-MJJN",
  password: "foo",
}

WEEKS = 6 # show signups for the last six weeks, rolling
SECS_IN_7_DAYS = 604800

SCHEDULER.every '30m', :first_in => 0 do
  STDERR.puts "======= Wufoo Fetch!"
  pages = 0
  page_start = 0
  entries = []

  while true
    STDERR.puts "Fetching from EntryId #{page_start}."
    pages += 1
    resp = HTTParty.get("https://elbenshira.wufoo.com/api/v3/forms/stone-test/entries.json?pageSize=100&pageStart=#{page_start}",
                        basic_auth: auth)

    if resp.code == 421
      STDERR.puts "======= Rate limit exceeded."
    end

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

  this_week = Time.now.to_i / SECS_IN_7_DAYS
  first_week = this_week - WEEKS
  weekly_counts = [0] * (WEEKS + 1)

  campus_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }
  next_step_counts = Hash.new { |h, k| h[k] = {label: k, value: 0} }

  entries.each do |entry|
    # Weekly counts
    week = DateTime.parse(entry["DateCreated"]).to_time.to_i / SECS_IN_7_DAYS
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
