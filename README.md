## Drone.io AWS Elastic Beanstalk Plugin

[![Build Status](https://drone.gwaz.org/api/badges/goodwillaz/drone-elastic-beanstalk/status.svg)](https://drone.gwaz.org/goodwillaz/drone-elastic-beanstalk)

This is a simple plugin that uses the [Elastic Beanstalk CLI](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)
to deploy code to Elastic Beanstalk environments.

### Basic Drone Usage

In `.drone.yml`:

```yaml
steps:
- name: deploy
  image: goodwillaz/drone-elastic-beanstalk
  settings:
    access_key:
      from_secret: aws_access_key
    secret_key:
      from_secret: aws_secret_key
    single_instance: true
    ec2_role: aws-elasticbeanstalk-ec2-role
    service_role: aws-elasticbeanstalk-service-role
    environment: my-eb-environment
    staged: true
```

### Docker Usage

Since this is a Docker image, it can be run directly via Docker (useful for testing).

```bash
$ docker build --rm -t ghcr.io/goodwillaz/drone-elastic-beanstalk:latest .
$ docker run --rm --privileged \
    -v /host/working/directory:/build \
    -w /build \
    -e PLUGIN_ACCESS_KEY=aws_access_key \
    -e PLUGIN_SECRET_KEY=aws_secret_key \
    -e PLUGIN_ENVIRONMENT=my-eb-environment \
    -e PLUGIN_DEBUG=true \
    drone-elastic-beanstalk:latest
```

### Available Settings

All options are technically optional, though the first two should really be used when using this in Drone

* `access_key` - AWS Access Key Id
* `secret_key` - AWS Secret Access Key
* `region` - AWS Region
* `label` - Label used for application version, order of precedence is this option, `$DRONE_TAG`, then first 12 characters of  
    `$DRONE_COMMIT`
* `staged` - Specify if this application should be deployed as is (`true`), or via the git `HEAD` (`false` or 
    not specified)
* `quiet` - Limits output of `eb deploy` or `eb create` command
* `no_hang` - Return right away, don't wait for `eb deploy` or `eb create` to finish
* `timeout` - Timeout in minutes for `eb deploy` or `eb create` command, default is 55 minutes
* `source` - CodeCommit source (_without_ `codecommit/`)
* `process` - Enable pre-processing of the application version
* `ec2_role` - The IAM role to use for EC2 instances during `eb create`, will be created if it doesn't exist, defaults to `aws-elasticbeanstalk-ec2-role`
* `service_role` - The IAM role to use for Elastic Beanstalk operations during `eb create`, will be created if it doesn't exist, defaults to `aws-elasticbeanstalk-service-role`
* `single_instance` - Whether or not `eb create` should launch as a single instance environment, defaults to `false`
* `modules` - An array of modules for this deployment
* `debug` - Set to true for verbose output

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (BSD 3-clause).
