/// Represents a piece of business logic that can be executed with parameters.
abstract class UseCase<Type, Params> {
  const UseCase();

  Future<Type> call(Params params);
}

/// A convenience type for use cases that do not accept parameters.
class NoParams {
  const NoParams();
}
