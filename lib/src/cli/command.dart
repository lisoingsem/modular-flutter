/// Base command interface
abstract class Command {
  Future<int> run(List<String> arguments);
}
