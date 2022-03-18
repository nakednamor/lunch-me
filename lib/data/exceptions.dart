class NameAlreadyExistsException implements Exception {
  String cause;

  NameAlreadyExistsException(this.cause);
}

class EmptyNameException implements Exception {
  String cause;

  EmptyNameException(this.cause);
}

class NameTooLongException implements Exception {
  String cause;

  NameTooLongException(this.cause);
}

class TagGroupNotFoundException implements Exception {
  int cause;

  TagGroupNotFoundException(this.cause);
}

class NegativeValueException implements Exception {
  int cause;

  NegativeValueException(this.cause);
}

class TagNotFoundException implements Exception {
  int cause;

  TagNotFoundException(this.cause);
}
