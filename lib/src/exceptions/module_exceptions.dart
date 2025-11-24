/// Base exception class for module-related errors
class ModuleException implements Exception {
  final String message;
  final dynamic cause;

  const ModuleException(this.message, [this.cause]);

  @override
  String toString() => 'ModuleException: $message';
}

/// Thrown when a module is not found
class ModuleNotFoundException extends ModuleException {
  const ModuleNotFoundException(String moduleName)
      : super('Module "$moduleName" not found');
}

/// Thrown when module metadata is invalid
class InvalidModuleException extends ModuleException {
  const InvalidModuleException(String message) : super(message);
}

/// Thrown when a module file already exists
class ModuleFileAlreadyExistsException extends ModuleException {
  const ModuleFileAlreadyExistsException(String path)
      : super('Module file already exists: $path');
}

/// Thrown when module JSON/YAML parsing fails
class InvalidModuleJsonException extends ModuleException {
  const InvalidModuleJsonException(String message) : super(message);
}
