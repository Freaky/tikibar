# Tikibar

Prototype for a new Ruby progress bar library, taking inspiration from Rust's
[indicatif](https://github.com/mitsuhiko/indicatif) crate.

## Synopsis

```ruby
require "tikibar"

# One of the many styles we might use.  Can also make custom ones.
bar = Tikibar::Styles::Bars::Fill

# Create a rendering thread all our output should go through
out = Tikibar::Display.new

# A template using Kernel.format filtered through Tikibar::Ansi
fmt = "%{bar.cyan} %<eta.dim>4s %<pct> 3d%% %{msg.green}"
background = Thread.new do
  items = Array.new(100) { rand(1000) }

  # Add a bar to the output, returning a thread-safe handle to it.
  pb = out.add(Tikibar::Progress.new(bar: bar, len: items.size - 1, template: fmt))

  out.puts "Processing array..."
  items.each_with_index do |n, i|
    pb.pos = i
    pb.message = "Item #{i} contains #{n}"
    out.puts "Ten down..." if i == 10
    sleep 0.04
  end

  # End with a message
  pb.finish("Bam, sorted!")
end

# Add another, completely different bar for another, concurrent task
spinner = Tikibar::Styles::Spinners::Twirl
fmt = "%<prefix>15s %{spinner} %{bar.red} %{pos}/%{len}"
pb = out.add(Tikibar::Progress.new(len: 256, bar: bar, spinner: spinner, template: fmt))
pb.prefix = "Bleep bloop"
0.upto(256) do |i|
  pb.prefix = pb.prefix.succ
  pb.pos = i
  sleep 0.03
end

# Clear the bar entirely, avoiding rendering it in the next loop.
pb.clear

background.join

out.puts "That's pretty much it!"

# Signal Tikibar::Display to exit
out.finish

# And we're back to normal rendering
puts "\\o/"

```

Output:

```
-% bundle exec examples/tiki.rb
Processing array...
Ten down...
█████░░░░░░░░░░░░░░░░░░░░░░░░░   3s  18% Item 18 contains 164
    Bleep blopn ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 23/256
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
