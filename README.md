
resque-pertry
=============

If you find this repo, don't bother with it yet.
It's a work in progress.

Cheers!

Setup
=====

```ruby
gem 'resque-pertry'
```

You'll need to run a migration to create the persistence table.

```ruby
require 'resque/pertry/migrations/create_resque_pertry_table'

class AddResquePertry < Resque::Pertry::Migrations::CreateResquePertryTable
  # if you are using db-charmer, you can easily specify the connection to use
  db_magic :connection => :resque_durability
end
```

You will also need to start [resque-scheduler](https://github.com/bvandenbos/resque-scheduler)

```
$ VERBOSE=1 rake environment resque:scheduler
```

Usage
=====

Your resque job needs to extend `Resque::Pertry::Job` :

```ruby
class HeavyLiftingJob
  extend Resque::Pertry::Job

  # specify Resque queue
  in_queue :critical

  def perform
    # do some heavy lifting here
  end
end
```

You can enqueue the job:

```ruby
HeavyLiftingJob.enqueue
```

Passing arguments to your job:

```ruby
HeavyLiftingJob.enqueue(:user_id => 42, :image_id => 24)
```

In your job class, you specify the arguments with `needs` :

```ruby
class HeavyLiftingJob
  extend Resque::Pertry::Job

  # specify Resque queue
  in_queue :critical

  needs :user_id, :image_id

  def perform
    # ...
  end
end
```

The arguments `user_id` and `image_id` will then be accessible as instance variables `@user_id` and `@image_id`
You can also specify a default value for your needs:

```ruby
needs :user_id, :image_id, :action => "delete"
```

Finally you can specify if your job should be persistent or not, and if it is, the properties to retry failed persistent jobs.
Non persistent jobs won't be retried at all.

```ruby
class HeavyLiftingJob
  extend Resque::Pertry::Job

  # specify Resque queue
  in_queue :critical

  # Set the persistence of the job using either:
  #   persistent
  #   non_persistent
  #
  # All jobs are persistent by default, so you don't have to specify it
  persistent

  # Retry properties:
  # set_retry_attempts <max_retries>
  #   Sets the maximum number of retries
  #   Ignored if set_retry_delays if specified
  #
  # set_retry_delay <seconds>
  #   Sets the number of seconds to wait before retrying a failed job
  #   Ignored if set_retry_delays if specified
  #
  # set_retry_delays <seconds>, <seconds>, ...
  #   Set an array of delays
  #   Which both indicate the number of attempts and the delay between retries
  #   Ignores set_retry_attempts and set_retry_delay
  #
  # set_retry_exceptions <SomeException>, <AnotherException>, ...
  #   Whitelist exceptions we want to retry.
  #   If specified, only the whitelisted exceptions will be retried,
  #   and all other exceptions will fail the job. 
  #   If not specified, all exceptions will be retried
  #   Can be combined with any other property
  #
  # set_retry_ttl <seconds>
  #   Sets the maximum time to live for a job, after this time has passed
  #   The job will be marked as failed even if it still has some retries left.
  #   Can be combined with any other property
  #

  # retry 5 times, enqueue job immediately
  set_retry_attempts 5

  # retry 10 times, wait 1 minute before enqueueing the job again
  set_retry_attempts 10
  set_retry_delay 1.minute

  # retry 3 times, wait time before enqueueing job increases after each attempt
  set_retry_delays 1.minute, 5.minutes, 15.minutes

  # retry every 30 seconds for 1 hour, as long as we are getting the exception ActiveRecord::ConnectionTimeoutError
  set_retry_ttl 1.hour
  set_retry_delay 30.seconds
  set_retry_exceptions ActiveRecord::ConnectionTimeoutError

  needs :user_id, :image_id, :action => "delete"

  def perform
    # ...
  end
end
```

