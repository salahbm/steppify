enum Environment { dev, prod }

class EnvironmentConfig {
  const EnvironmentConfig({
    this.environment = Environment.dev,
    this.appName = 'Steppify',
  });

  final Environment environment;
  final String appName;

  bool get isProduction => environment == Environment.prod;
}
