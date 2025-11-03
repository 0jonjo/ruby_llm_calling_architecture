# LLM Function Calling Demo

**Try LLM function calling in one command!**

## Setup (one time)

```bash
bundle install
cp .env.example .env
# Edit .env and add your API key:
# OPENAI_API_KEY=sk-...
```

## Run

```bash
irb -r bundler/setup -r dotenv/load -r ./chat.rb
```

That's it! Now you have an IRB session with LLM ready to call tools.

Then chat:

```ruby
ask("What's the weather in Paris?")
ask("Where can I go with my Gold pass?")
ask("Create a 3-day itinerary for Tokyo")
```

**That's it!** The LLM automatically calls the tools when needed.

## How it works

1. You ask a question
2. The LLM decides if it needs a tool
3. The LLM calls the tool with the right parameters
4. The LLM synthesizes a natural response

Available tools:
- **WeatherTool** - Get weather info
  _Purpose: Demonstrates simple API integration pattern_

- **DestinationSearchTool** - Find destinations based on SkyTraveler pass membership (Silver, Gold, Platinum)
  _Purpose: Demonstrates business rules enforcement with tiered access control_

- **ItineraryBuilderTool** - Create travel plans
  _Purpose: Demonstrates structured data extraction pattern using Halt pattern_

## Examples

```ruby
# Weather
ask("What's the weather in Tokyo?")

# SkyTraveler Pass Destinations (Business Rules Demo!)
ask("Where can I go with my Silver pass?")
# Shows 8 regional destinations (North America, Central America)

ask("What destinations are available with Gold membership?")
# Shows 18 destinations (Silver + Europe + South America)

ask("Show me beach destinations with Platinum pass")
# Shows beach destinations from all 30 worldwide locations

ask("I have a Silver pass, where can I travel in winter?")
# Filters Silver destinations by season

# Multi-turn with context
ask("What's the weather in Paris?")
ask("Is it good for traveling?")      # Remembers we're talking about Paris
ask("Create a 5-day itinerary")       # Still knows it's Paris!
```
