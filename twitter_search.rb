require 'optparse'
require 'twitter'

############# Twitter search 'client' #############

# A search client that displays results on the console. Can be modified to return results as objects (perhaps
# using a yield block) but then it's not much more than a thin wrapper around the 'twitter' gem.
#
# Note: assumes that the 'twitter' gem is installed (`gem install twitter`) and that the appropriate environment
# variables are set for the app id/secret and access token/secret for the app.
class TwitterSearchClient
  def initialize(client = nil)
    @client = client
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def search_for_tweets(content)  
    puts "Searching for tweets containing '#{content}' (max: 1000)...\n#{separator}\n"
    results = client.search(content)

    if results && results.any?
      results.each do |tweet|
        content = tweet.text.strip
        puts "@#{tweet.user.screen_name}:\n#{content}\n#{separator}"
      end
    else
      puts "No results found matching '#{content}'"
    end
  end

  def search_for_users(username)
    puts "Searching for users with names containing '#{username}' (max: 1000)...\n#{separator}\n"
    users = client.user_search(username)

    if users && users.any?
      users.each do |user|
        print "@#{user.screen_name}"

        if user.description.strip.length > 0
          puts ":\n#{user.description}\n"
        else
          puts "\n"
        end
        puts separator
      end
    else
      puts "No users found matching '#{username}'"
    end
  end

  private
  def separator
    "----------------------------------------------"
  end
end

############# command-line driver and search-mode determination #############

# primarily wraps the optparse library, and forks based upon search mode when calling the search client's
# search methods.
class TwitterSearchApp
  def initialize(args)
    @client = TwitterSearchClient.new
    @mode, @search_value = parse_args(args)
  end

  def run
    case @mode
    when :tweet
      @client.search_for_tweets(@search_value)
    when :user
      @client.search_for_users(@search_value)
    end
  end

  private
  # splitting this out allows it to be mocked for potential unit testing
  def parse_args(args)
    # prevent the inner block from shadowing these by pre-declaring them
    mode = nil
    search_value = nil

    # parse command line options using optparse
    parser = OptionParser.new do |opts|

      opts.banner ="Usage: twitter_search.rb <search_mode> <search_value>"

      opts.separator ""
      opts.separator "Search modes:"

      opts.on("-t", "--tweet SEARCHTEXT", "Search for SEARCHTEXT in individual tweet contents. Use quotes to include spaces.") do |val|
        mode = :tweet
        search_value = val
      end

      opts.on("-u", "--user USERNAME", "Search for Twitter usernames containing USERNAME.") do |val|
        mode = :user
        search_value = val
      end

      opts.on_tail("-h", "--help", "Show this message.") do
        puts opts
        exit
      end

    end

    # actually perform the parsing
    parser.parse!(args)

    # both search mode and search value are required
    if mode.nil? || search_value.nil?
      puts parser.help
      exit(1)
    end

    return mode, search_value
  end
end

############# actually run the console app #############

# args are passed in explicitly for testability (we should be able to send in different ARGV values and see what happens, to
# simulate end-to-end testing)
TwitterSearchApp.new(ARGV).run