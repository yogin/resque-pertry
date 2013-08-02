resque-pertry
=============

Setup
-----

```ruby
gem 'resque-pertry'
```

Wherever you include resque's tasks, you should add:

```ruby
require 'resque/tasks'
require 'resque/pertry/tasks'
```

You'll need to run a migration to create the persistence table.

```ruby
require 'resque/pertry/migrations/create_resque_pertry_table'

class AddResquePertry < Resque::Pertry::Migrations::CreateResquePertryTable
  # if you are using db-charmer, you can easily specify the connection to use
  db_magic :connection => :resque
end
```

The associated model is `Resque::Pertry::ResquePertryPersistence`, feel free to add your own code in there if you need (such as db_magic)

You will also need to start [resque-scheduler](https://github.com/bvandenbos/resque-scheduler) and the resque pertry purger

```
$ VERBOSE=1 rake resque:scheduler
$ VERBOSE=1 rake resque:pertry:purger
```

The purger's default values will have it run every 5 minutes, and purge 100 failed jobs from redis and another 100 failed jobs from the database.
You can add hooks in your application if you want to process the purged jobs further (you may want to log the jobs you are purging):

```ruby
Resque::Pertry::Purger.after_redis_purge do |job,redis|
  # do something with this job from resque's failed queue
end

Resque::Pertry::Purger.after_database_purge do |job|
  # do something with this job from the persistence table
end
```

Usage
-----

Your resque jobs need to inherit from `Resque::Plugins::Pertry` :

```ruby
class SomeJob < Resque::Plugins::Pertry

  # specify Resque queue
  in_queue :critical

  def perform
    # do something
  end
end
```

You can enqueue the job:

```ruby
SomeJob.enqueue
```

You can pass arguments to your job:

```ruby
SomeJob.enqueue(:user_id => 42, :image_id => 24)
```

In your job class, you specify the arguments with `needs` :

```ruby
class SomeJob < Resque::Plugins::Pertry

  # specify Resque queue
  in_queue :critical

  needs :user_id, :image_id

  def perform
    # do something with @user_id and @image_id
  end
end
```

The arguments `user_id` and `image_id` will then be accessible as instance variables `@user_id` and `@image_id`
You can also specify a default value for your needs:

```ruby
needs :user_id, :image_id, :action => "delete"
```

Finally you can specify if your job should be persistent or not, and if it is, the properties to retry failed persistent jobs.
All jobs including `Resque::Plugins::Pertry` are persistent by default. Non persistent jobs act just like regular resque jobs.

To set a job as non persistent, simply:

```ruby
class SomeJob < Resque::Plugins::Pertry

  # set job as non persistent, acts like a regular resque job
  non_persistent

  ...
end
```

To retry a persistent job, you have several properties you can set:

  * `set_retry_attempts <max_retries>`

    Sets the maximum number of times we will retry a failed job. 
    The total number of times a job will run is max_retries + 1 (the original run).

  * `set_retry_delay <seconds>`

    Sets the number of seconds to wait before enqueueing a failed job again

  * `set_retry_delays <seconds>, <seconds>, ...`

    Set an array of delays. 
    The number of items will be used to defined `max_retries`, while each value will be used in turn for each consecutive retry delay.
    If this is set, `set_retry_attempts` and `set_retry_delay` will be ignored

  * `set_retry_exceptions <SomeException>, <SomeOtherException>, ...`

    Sets a whitelist of exceptions you want to retry. Any other exceptions will not be retried.
    If not set, all exceptions will be retried (default).
    This property can be combined with any other property.

  * `set_retry_ttl <seconds>`

    Sets the maximum time to live for a job, after which the job will not be retried, even if it has attempts lefts.
    This property can be combined with any other property.

The default settings for all persistent jobs are:

```ruby
# retry a failed job once, enqueue the job immediately, job expires in 1 week
set_retry_attempts 1
set_retry_ttl 1.week
```

Here are some exemples of retry settings:

```ruby
# retry 5 times, enqueue job immediately
set_retry_attempts 5
```

```ruby
# retry 10 times, wait 1 minute before enqueueing the job again
set_retry_attempts 10
set_retry_delay 1.minute
```

```ruby
# retry 3 times, wait time before enqueueing job increases after each attempt
set_retry_delays 1.minute, 5.minutes, 15.minutes
```

```ruby
# retry every 30 seconds for 1 hour, as long as we are getting the exception ActiveRecord::ConnectionTimeoutError
set_retry_ttl 1.hour
set_retry_delay 30.seconds
set_retry_exceptions ActiveRecord::ConnectionTimeoutError
```

TODO
----

Write some specs!

How to contribute
-----------------

Tell me what you think about this gem, things you like or don't about it, how it could be better.
Pull Requests most welcomed.


