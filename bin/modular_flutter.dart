#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/cli/command_runner.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
