sealed class DataResult<T> {
  const DataResult();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace? stackTrace) onFailure,
  });
}

final class DataSuccess<T> extends DataResult<T> {
  const DataSuccess(this.value);

  final T value;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace? stackTrace) onFailure,
  }) => onSuccess(value);
}

final class DataFailure<T> extends DataResult<T> {
  const DataFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace? stackTrace) onFailure,
  }) => onFailure(error, stackTrace);
}
