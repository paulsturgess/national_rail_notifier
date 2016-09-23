# National Rail Notifier

[ ![Codeship Status for paulsturgess/national_rail_notifier](https://codeship.com/projects/5eb10540-6411-0134-11ea-7ac11de88606/status?branch=master)](https://codeship.com/projects/175514)

This Ruby app will Tweet when trains are late/cancelled.

I use this to notify me for the trains I get for my daily commute :)

You can see it in action via [@TrainNotifier](https://twitter.com/trainnotifier)

## Config

Rename `.env.sample` to `.env` and fill in the credentials.

You will need a [Twitter account](https://twitter.com/) you want to tweet from and a [Twitter application](https://apps.twitter.com/).

You will also need a National Rail Token which you can get by [registering for access to the Darwin Data Feeds via OpenLDBWS](http://www.nationalrail.co.uk/100296.aspx).

Finally you can specify the trains you want to monitor by renaming `trains.json.sample` to `trains.json` and changing the details. You can get a list of the station codes from the [National Rail website](http://www.nationalrail.co.uk/stations_destinations/48541.aspx).

## Run the notifier

`ruby run.rb`

The notifier is smart enough not to blast out loads of duplicate tweets.

I run the notifier every few minutes via [Lingon for Mac](https://www.peterborgapps.com/lingon/) but [Cron](https://en.wikipedia.org/wiki/Cron) would also do the job.

I recommend checking the National Rail developer guidelines for fair usage.

## Tests and code coverage

In the project root run:

`rspec spec`

## Rubocop

In the project root run:

`rubocop`
