import 'dart:io';

import 'package:dart_pty/dart_pty.dart';
import 'package:global_repository/global_repository.dart';

class TerminalUtil {
  const TerminalUtil._();
  static PseudoTerminal getShellTerminal({
    String exec,
    int row = 25,
    int column = 80,
    String home,
    bool useIsolate,
    List<String> arguments,
  }) {
    String executable = exec;
    if (Platform.environment.containsKey('SHELL') && executable == null) {
      executable = Platform.environment['SHELL'];
      // 取的只是执行的文件名
      executable = executable.replaceAll(RegExp('.*/'), '');
    } else {
      if (Platform.isMacOS) {
        executable ??= 'bash';
      } else if (Platform.isWindows) {
        executable ?? 'cmd';
      } else if (Platform.isAndroid) {
        executable ??= 'sh';
      }
    }
    try {
      Directory(RuntimeEnvir.homePath).createSync(recursive: true);
      Directory(RuntimeEnvir.tmpPath).createSync(recursive: true);
    } catch (e) {
      Log.e('create dir error : $e');
    }
    final Map<String, String> environment = {
      'TERM': 'xterm-256color',
      'PATH': RuntimeEnvir.path,
      'TMPDIR': RuntimeEnvir.tmpPath,
    };
    if (Platform.isAndroid) {
      environment['HOME'] = home ?? RuntimeEnvir.homePath;
      environment['SHELL'] = RuntimeEnvir.binPath + '/' + executable;
      environment['TERMUX_PREFIX'] = RuntimeEnvir.usrPath;
      if (File('${RuntimeEnvir.usrPath}/lib/libtermux-exec.so').existsSync()) {
        environment['LD_PRELOAD'] =
            '${RuntimeEnvir.usrPath}/lib/libtermux-exec.so';
      }
    } else {
      environment['HOME'] = RuntimeEnvir.envir()['HOME'];
    }
    return PseudoTerminal(
      executable: executable,
      workingDirectory: RuntimeEnvir.homePath,
      environment: environment,
      row: row,
      // 不能减一了
      column: column,
      arguments: arguments ?? ['-l'],
      useIsolate: useIsolate,
    );
  }
}
