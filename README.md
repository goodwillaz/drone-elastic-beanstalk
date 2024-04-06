## Drone.io AWS Elastic Beanstalk Plugin

[![Build Status](https://drone.gwaz.org/api/badges/goodwillaz/drone-elastic-beanstalk/status.svg)](https://drone.gwaz.org/goodwillaz/drone-elastic-beanstalk)

This is a plugin that by default uses the AWS CDK to deploy Elastic Beanstalk applications.
Example repo coming soon...

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
    application: MyAppName
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
    -e PLUGIN_APPLICATION=MyAppName \
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
* `staged` - Specify if this application should be deployed as is (`true`), or via the git `HEAD` (`false` or not specified)
* `application` - Specify the application name in AWS.  It must exist.
* `deploy_cmd` - Custom deploy command to use.  By default, it is `cdk deploy --all --require-approval never --progress events`.
* `debug` - Set to true for verbose output

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (BSD 3-clause).
