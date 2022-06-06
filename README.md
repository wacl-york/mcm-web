# Base Sinatra App

## Creating a new app from this repo template

In GitHub, click "Use this template". 
Then provide a repo name and description for your new app.
Finally click "Create repository from template".

Then `git clone` your newly-created repo.

As per the Gemfile, ensure you are using Ruby ~> 2.7.1 and then run:

```shell
rake rename name=NewAppName
```

(If rake complains about a version mismatch, feel free to delete Gemfile.lock - the `rename` script will do this anyway)

## Running in Development

You will need:

* docker-compose (and, therefore, docker)

There's a single command to get the app ready for local development:

```shell
rake init
```

This runs `build`, `bundle:install` and `up`.
You can then browse to [http://localhost](http://localhost).

### Running tests

```shell
rake spec
```

### Gem Changes

If you modify the Gemfile, use rake to run bundle in the docker container:

```shell
rake bundle update
```

### Bundler Audit

```shell
rake audit
```

### Other rake tasks

See `rake -T` for other available rake tasks. Most are available in `lib/faculty/rake`.

If you are working with node (e.g. webpack), add the following to `Rakefile`:

```ruby
Faculty::Rake::NodeTasks.new
```

#### `Faculty::Rake::DockerTasks`

If you have a non-standard `docker-compose` setup, you can specify which services the tasks will be run against.
You can also specify which services are started when running `rake up`.

```ruby
Faculty::Rake::DockerTasks.new(builder: :builder, app: :app, up_services: 'web')
```

#### `Faculty::Rake::NodeTasks`

We currently use node 14 - if you wish to use a different version of node, you can specify this:

```ruby
Faculty::Rake::NodeTasks.new(node_version: 15)
```

## Deploying to AWS

For your first push to AWS, do this through Github Actions. Set up as per the
[documentation on new deployments](https://wiki.york.ac.uk/display/ittechdocs/Creating+new+AWS+Deployments)
and ensure the app deploys.

Once the stack exists in dev, you can deploy from the local environment using
```shell
rake deploy
```

We make use of the fact that cloudformation will reuse previously defined parameters when updating a stack to
save us the headache of sharing parameter overrides between github actions and rake.

The deploy command can take a block that will be run before deployment; in `Rakefile`:

```ruby
Faculty::Rake::Deploy.new do
  puts 'Extra tasks here'
end
```

If your stack name does not match the repository name, you can specify the stack name to use instead.
This is likely for older apps, that were originally deployed from BitBucket.

```ruby
Faculty::Rake::Deploy.new(stack_name: 'stack-name-here')
```

## Docker notes

The images used in development are built in our
[docker-images](https://github.com/university-of-york/faculty-dev-docker-images) repository. 
They use the official [AWS lambda ruby images](https://gallery.ecr.aws/lambda/ruby) as a base.
