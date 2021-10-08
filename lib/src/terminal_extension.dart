import 'dart:async';
import 'dart:io';
import 'package:dart_pty/dart_pty.dart';
import 'package:global_repository/global_repository.dart';

const _tag = 'define function';

extension DefineFunction on PseudoTerminal {
  Future<void> defineTermFunc(
    String function, {
    String tmpFilePath,
  }) async {
    tmpFilePath ??= RuntimeEnvir.tmpPath + '/defineTermFunc';
    Log.d('定义函数中...--->$tmpFilePath', tag: _tag);
    // Log.w(function);
    final File tmpFile = File(tmpFilePath);
    await tmpFile.writeAsString(function);
    Log.d('创建临时脚本成功...->${tmpFile.path}', tag: _tag);
    Log.d('script -> source $tmpFilePath', tag: _tag);
    Log.d('rm -rf $tmpFilePath', tag: _tag);
    // 这种写法为了兼容 windows 这垃圾系统
    '''
    export AUTO=TRUE\n
    source $tmpFilePath
    rm -rf $tmpFilePath
    '''
        .trim()
        .split('')
        .forEach(
      (String element) {
        write(element);
      },
    );
    write('\n');
    final Completer lock = Completer();
    StreamSubscription<String> subscription;
    schedulingRead();
    subscription = out.listen((event) async {
      // Log.w(event);
      // ignore: avoid_slow_async_io
      final bool exist = await tmpFile.exists();
      if (!exist) {
        subscription.cancel();
        lock.complete();
        out.drain();
      }
      schedulingRead();
    });
    Log.d('创建临时脚本结束', tag: _tag);
    await lock.future;
  }
}
