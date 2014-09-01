# FullPie widget
This is a simple widget that lets you render pie charts in Dashing.
Forked from [stevenleeg/pie.coffee](https://gist.github.com/stevenleeg/6273841)
It looks a little bit like this:

![Screenshot](http://i.imgur.com/NNkCWNz.jpg)

# Usage

`dashboard.erb`:
```erb
<li data-row="2" data-col="1" data-sizex="1" data-sizey="1">
  <div data-id="bookmarks_frequency" data-view="Fullpie" data-title="Bookmark freq."></div>
</li>
```

`my_job.rb`:
```ruby
data = [
  { label: "Label1", value: 16 },
  { label: "Label2", value: 34 },
  { label: "Label3", value: 10 },
  { label: "Label4", value: 40 },
  { label: "Label5", value: 20 },
]

send_event 'bookmarks_frequency', { value: data }
```

I hope you like it!
