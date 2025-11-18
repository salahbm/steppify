/// Generic use case contract to standardize business logic classes.
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Represents a use case with no input parameters.
class NoParams {
  const NoParams();
}
