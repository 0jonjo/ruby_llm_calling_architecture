#!/usr/bin/env ruby
# Destination Search Tool - Search travel destinations based on travel pass membership
# This demonstrates business rules implementation with membership tiers

class DestinationSearchTool
  def execute(pass_tier:, query: "any", season: "any", limit: 10)
    # Validate inputs
    pass_tier = pass_tier.to_s.downcase
    unless ["silver", "gold", "platinum"].include?(pass_tier)
      return error_response("Invalid pass tier. Must be: silver, gold, or platinum")
    end

    limit = [[limit.to_i, 1].max, 20].min

    # Get destinations available for this pass tier (business rule!)
    available_destinations = get_destinations_by_pass(pass_tier)

    # Filter by query and season if provided
    results = filter_destinations(available_destinations, query, season, limit)

    if results.empty?
      {
        status: "no_results",
        message: "No destinations found for #{pass_tier.capitalize} pass matching your criteria.",
        pass_tier: pass_tier.capitalize,
        total_available: available_destinations.size,
        results: []
      }
    else
      {
        status: "success",
        pass_tier: pass_tier.capitalize,
        access_info: get_pass_benefits(pass_tier),
        total_available: available_destinations.size,
        showing: results.size,
        filters: { query: query, season: season },
        results: results
      }
    end
  rescue StandardError => e
    error_response("Search failed: #{e.message}")
  end

  private

  # BUSINESS RULE: SkyTraveler Pass Destinations
  # Each pass tier unlocks specific destination categories

  # Silver Pass - Regional destinations (8 destinations)
  SILVER_DESTINATIONS = [
    {
      name: "Mexico City, Mexico",
      region: "North America",
      type: "culture",
      activities: ["culture", "food", "history", "museums"],
      best_seasons: ["spring", "fall", "winter"],
      highlights: "Ancient pyramids, world-class museums, street food"
    },
    {
      name: "Cancun, Mexico",
      region: "North America",
      type: "beach",
      activities: ["beach", "diving", "relaxation", "nightlife"],
      best_seasons: ["winter", "spring"],
      highlights: "Caribbean beaches, Mayan ruins, resort paradise"
    },
    {
      name: "Toronto, Canada",
      region: "North America",
      type: "city",
      activities: ["culture", "food", "entertainment", "shopping"],
      best_seasons: ["summer", "fall"],
      highlights: "Multicultural city, CN Tower, vibrant neighborhoods"
    },
    {
      name: "Vancouver, Canada",
      region: "North America",
      type: "city",
      activities: ["nature", "food", "outdoor sports", "culture"],
      best_seasons: ["summer", "fall"],
      highlights: "Mountains meet ocean, diverse cuisine, outdoor activities"
    },
    {
      name: "Miami, USA",
      region: "North America",
      type: "beach",
      activities: ["beach", "nightlife", "art", "food"],
      best_seasons: ["winter", "spring"],
      highlights: "Art Deco architecture, Latin culture, beautiful beaches"
    },
    {
      name: "San Francisco, USA",
      region: "North America",
      type: "city",
      activities: ["culture", "food", "technology", "nature"],
      best_seasons: ["fall", "spring"],
      highlights: "Golden Gate Bridge, tech culture, steep hills"
    },
    {
      name: "Costa Rica",
      region: "Central America",
      type: "adventure",
      activities: ["nature", "wildlife", "adventure", "beach"],
      best_seasons: ["winter", "spring"],
      highlights: "Eco-tourism paradise, biodiversity, beaches and rainforests"
    },
    {
      name: "Panama City, Panama",
      region: "Central America",
      type: "culture",
      activities: ["culture", "history", "beach", "shopping"],
      best_seasons: ["winter", "spring"],
      highlights: "Panama Canal, modern skyline, Caribbean and Pacific access"
    }
  ].freeze

  # Gold Pass - Continental destinations (Silver + 10 more = 18 total)
  GOLD_DESTINATIONS = [
    {
      name: "Barcelona, Spain",
      region: "Europe",
      type: "city",
      activities: ["culture", "architecture", "beach", "food"],
      best_seasons: ["spring", "summer", "fall"],
      highlights: "Gaudí masterpieces, Mediterranean beaches, vibrant culture"
    },
    {
      name: "Lisbon, Portugal",
      region: "Europe",
      type: "city",
      activities: ["culture", "food", "history", "beach"],
      best_seasons: ["spring", "summer", "fall"],
      highlights: "Charming hills, tram rides, pastéis de nata"
    },
    {
      name: "Prague, Czech Republic",
      region: "Europe",
      type: "city",
      activities: ["culture", "history", "architecture", "beer"],
      best_seasons: ["spring", "summer", "fall"],
      highlights: "Medieval architecture, astronomical clock, affordable luxury"
    },
    {
      name: "Athens, Greece",
      region: "Europe",
      type: "culture",
      activities: ["history", "culture", "food", "beach"],
      best_seasons: ["spring", "fall"],
      highlights: "Ancient ruins, Acropolis, Mediterranean cuisine"
    },
    {
      name: "Rome, Italy",
      region: "Europe",
      type: "culture",
      activities: ["history", "culture", "food", "art"],
      best_seasons: ["spring", "fall"],
      highlights: "Colosseum, Vatican City, Italian cuisine"
    },
    {
      name: "London, UK",
      region: "Europe",
      type: "city",
      activities: ["culture", "history", "museums", "theater"],
      best_seasons: ["summer", "spring"],
      highlights: "British Museum, royal palaces, world-class theater"
    },
    {
      name: "Buenos Aires, Argentina",
      region: "South America",
      type: "city",
      activities: ["culture", "tango", "food", "nightlife"],
      best_seasons: ["spring", "fall"],
      highlights: "Tango capital, European architecture, incredible steakhouses"
    },
    {
      name: "Lima, Peru",
      region: "South America",
      type: "culture",
      activities: ["food", "culture", "history", "beach"],
      best_seasons: ["summer", "fall"],
      highlights: "Culinary capital, Machu Picchu gateway, colonial architecture"
    },
    {
      name: "Rio de Janeiro, Brazil",
      region: "South America",
      type: "beach",
      activities: ["beach", "carnival", "nature", "nightlife"],
      best_seasons: ["summer", "fall"],
      highlights: "Christ the Redeemer, Copacabana beach, samba"
    },
    {
      name: "Santiago, Chile",
      region: "South America",
      type: "city",
      activities: ["wine", "mountains", "culture", "food"],
      best_seasons: ["spring", "fall"],
      highlights: "Wine valleys, Andes views, modern Latin American cuisine"
    }
  ].freeze

  # Platinum Pass - Worldwide luxury destinations (Silver + Gold + 12 more = 30 total)
  PLATINUM_DESTINATIONS = [
    {
      name: "Tokyo, Japan",
      region: "Asia",
      type: "city",
      activities: ["culture", "food", "technology", "shopping"],
      best_seasons: ["spring", "fall"],
      highlights: "Cherry blossoms, cutting-edge tech, incredible cuisine"
    },
    {
      name: "Dubai, UAE",
      region: "Middle East",
      type: "luxury",
      activities: ["luxury", "shopping", "beach", "adventure"],
      best_seasons: ["winter", "spring"],
      highlights: "World's tallest building, luxury shopping, desert safaris"
    },
    {
      name: "Singapore",
      region: "Asia",
      type: "city",
      activities: ["food", "culture", "shopping", "luxury"],
      best_seasons: ["winter", "spring"],
      highlights: "Gardens by the Bay, hawker food culture, modern architecture"
    },
    {
      name: "Bali, Indonesia",
      region: "Asia",
      type: "beach",
      activities: ["beach", "culture", "yoga", "diving"],
      best_seasons: ["spring", "summer", "fall"],
      highlights: "Hindu temples, rice terraces, world-class surfing"
    },
    {
      name: "Maldives",
      region: "Asia",
      type: "luxury",
      activities: ["beach", "diving", "luxury", "relaxation"],
      best_seasons: ["winter", "spring"],
      highlights: "Overwater villas, pristine reefs, ultimate luxury"
    },
    {
      name: "Sydney, Australia",
      region: "Oceania",
      type: "city",
      activities: ["beach", "culture", "food", "outdoor"],
      best_seasons: ["spring", "summer", "fall"],
      highlights: "Opera House, Bondi Beach, harbor views"
    },
    {
      name: "Auckland, New Zealand",
      region: "Oceania",
      type: "adventure",
      activities: ["nature", "adventure", "wine", "culture"],
      best_seasons: ["summer", "fall"],
      highlights: "Lord of the Rings scenery, Māori culture, adventure sports"
    },
    {
      name: "Paris, France",
      region: "Europe",
      type: "culture",
      activities: ["culture", "art", "food", "luxury"],
      best_seasons: ["spring", "fall"],
      highlights: "Eiffel Tower, Louvre Museum, haute cuisine"
    },
    {
      name: "Swiss Alps, Switzerland",
      region: "Europe",
      type: "luxury",
      activities: ["skiing", "luxury", "nature", "hiking"],
      best_seasons: ["winter", "summer"],
      highlights: "World-class ski resorts, chocolate and watches"
    },
    {
      name: "Iceland",
      region: "Europe",
      type: "adventure",
      activities: ["nature", "northern lights", "adventure", "hot springs"],
      best_seasons: ["winter", "summer"],
      highlights: "Northern lights, dramatic landscapes, Blue Lagoon"
    },
    {
      name: "Cape Town, South Africa",
      region: "Africa",
      type: "adventure",
      activities: ["nature", "wine", "beach", "wildlife"],
      best_seasons: ["summer", "fall"],
      highlights: "Table Mountain, wine country, penguin beaches"
    },
    {
      name: "Marrakech, Morocco",
      region: "Africa",
      type: "culture",
      activities: ["culture", "food", "shopping", "adventure"],
      best_seasons: ["spring", "fall", "winter"],
      highlights: "Medina markets, riads, Sahara desert access"
    }
  ].freeze

  # BUSINESS RULE: Get destinations available for each pass tier
  def get_destinations_by_pass(pass_tier)
    case pass_tier
    when "silver"
      SILVER_DESTINATIONS
    when "gold"
      SILVER_DESTINATIONS + GOLD_DESTINATIONS
    when "platinum"
      SILVER_DESTINATIONS + GOLD_DESTINATIONS + PLATINUM_DESTINATIONS
    else
      []
    end
  end

  # Get pass tier benefits info
  def get_pass_benefits(pass_tier)
    case pass_tier
    when "silver"
      {
        tier: "Silver",
        destinations_count: SILVER_DESTINATIONS.size,
        regions: ["North America", "Central America"],
        description: "Access to regional destinations"
      }
    when "gold"
      {
        tier: "Gold",
        destinations_count: (SILVER_DESTINATIONS + GOLD_DESTINATIONS).size,
        regions: ["North America", "Central America", "South America", "Europe"],
        description: "Access to continental destinations including all Silver destinations"
      }
    when "platinum"
      {
        tier: "Platinum",
        destinations_count: (SILVER_DESTINATIONS + GOLD_DESTINATIONS + PLATINUM_DESTINATIONS).size,
        regions: ["Worldwide"],
        description: "Unlimited worldwide access including luxury destinations"
      }
    end
  end

  def filter_destinations(destinations, query, season, limit)
    query_lower = query.to_s.downcase

    filtered = destinations.select do |dest|
      # Match query if provided
      query_match = query == "any" ||
                    dest[:type].to_s.include?(query_lower) ||
                    dest[:activities].any? { |act| act.include?(query_lower) || query_lower.include?(act) } ||
                    dest[:name].downcase.include?(query_lower)

      # Match season if provided
      season_match = season == "any" || dest[:best_seasons].include?(season)

      query_match && season_match
    end

    filtered.take(limit).map { |dest| format_destination(dest) }
  end

  def format_destination(dest)
    {
      name: dest[:name],
      region: dest[:region],
      type: dest[:type],
      best_for: dest[:activities].join(", "),
      best_seasons: dest[:best_seasons].join(", "),
      highlights: dest[:highlights]
    }
  end

  def error_response(message)
    {
      status: "error",
      message: message,
      results: []
    }
  end
end

# Example usage (uncomment to test)
# tool = DestinationSearchTool.new
# puts JSON.pretty_generate(tool.execute(query: "beach", budget: "budget", limit: 3))
# puts JSON.pretty_generate(tool.execute(query: "skiing", season: "winter"))
# puts JSON.pretty_generate(tool.execute(query: "culture", budget: "budget"))
