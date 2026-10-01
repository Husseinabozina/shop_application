import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const exportPortfolio = bool.fromEnvironment('EXPORT_PORTFOLIO_SHOTS');

Future<void> preparePortfolioCapture() async {
  if (!exportPortfolio) return;
  final fonts = FontLoader('Lato')
    ..addFont(rootBundle.load('assets/fonts/Lato-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Lato-Bold.ttf'));
  await fonts.load();
  await (FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  HttpOverrides.global = _PortfolioImages();
}

Future<void> capturePortfolio(WidgetTester tester, String name) async {
  if (!exportPortfolio) return;
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last)).removeCurrentSnackBar();
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('portfolio-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/portfolio-screenshots').createSync(recursive: true);
    File('build/portfolio-screenshots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
  });
}

class _PortfolioImages extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageClient();
}

class _ImageClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest(url);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageRequest implements HttpClientRequest {
  final Uri url;
  _ImageRequest(this.url);
  @override
  HttpHeaders get headers => _Headers();
  @override
  Future<HttpClientResponse> close() async {
    final file = File('build/portfolio-images/${url.pathSegments.last}.jpg');
    return _ImageResponse(file.existsSync() ? file.readAsBytesSync() : [], file.existsSync());
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> bytes;
  final bool exists;
  _ImageResponse(this.bytes, this.exists);
  @override
  int get statusCode => exists ? 200 : 404;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
    {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(bytes).listen(onData, onError: onError,
        onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
