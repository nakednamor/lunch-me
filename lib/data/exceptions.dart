class TagException implements Exception {
  String cause;

  TagException(this.cause);
}

class TagGroupException implements Exception {
  String cause;

  TagGroupException(this.cause);
}

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

class NameNotUUIDException implements Exception {
  String cause;

  NameNotUUIDException(this.cause);
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

class MissingValueException implements Exception {
  String field;

  MissingValueException(this.field);
}

class InvalidUrlException implements Exception {
  String url;

  InvalidUrlException(this.url);
}

class RecipeNotFoundException implements Exception {
  int cause;

  RecipeNotFoundException(this.cause);
}

class RecipeAlreadyExistsException implements Exception {
  int cause;

  RecipeAlreadyExistsException(this.cause);
}

class PhotoAlreadyExistsException implements Exception {}
