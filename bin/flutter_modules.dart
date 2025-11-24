#!/usr/bin/env dart

import 'dart:io';
import 'package:flutter_modules/src/cli/command_runner.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner();
  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
