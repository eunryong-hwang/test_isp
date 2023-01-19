// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: WebViewExample()));
}

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

const String kLocalExamplePage = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>Load file or HTML string example</title>
</head>
<body>

<h1>Local demo page</h1>
<p>
  This is an example page used to demonstrate how to load a local file or HTML
  string using the <a href="https://pub.dev/packages/webview_flutter">Flutter
  webview</a> plugin.
</p>

</body>
</html>
''';

const String kTransparentBackgroundPage = '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>Transparent background test</title>
  </head>
  <style type="text/css">
    body { background: transparent; margin: 0; padding: 0; }
    #container { position: relative; margin: 0; padding: 0; width: 100vw; height: 100vh; }
    #shape { background: red; width: 200px; height: 200px; margin: 0; padding: 0; position: absolute; top: calc(50% - 100px); left: calc(50% - 100px); }
    p { text-align: center; }
  </style>
  <body>
    <div id="container">
      <p>Transparent background test</p>
      <div id="shape"></div>
    </div>
  </body>
  </html>
''';

const String token =
    'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJRRUVkbHRieVhpN2RBVWNMYjUwM1Bib1dzUDRxM2xZYlZzd3dRb00waTE0In0.eyJleHAiOjE2NzQwOTI5NTQsImlhdCI6MTY3NDA4OTM1NCwiYXV0aF90aW1lIjoxNjc0MDQ3MjcxLCJqdGkiOiIyY2I3ZjZlNC1iMDU4LTQxMTItYWM2YS04NWVmNmNjMWVmMWIiLCJpc3MiOiJodHRwczovL2FjY291bnRzLmlkLWltLmRldi9hdXRoL3JlYWxtcy9oZWFsZXJiIiwiYXVkIjoiYWNjb3VudCIsInN1YiI6ImY6OWQ0YWM1YmItNDU2Yy00OGQxLThiN2QtNDI3MjZlMWUzODgzOjAwbXhfbnE5cDk3N3Rfc19kYnN6dm5fZF9vX3hfb2JfeSIsInR5cCI6IkJlYXJlciIsImF6cCI6InRlc3QtY2xpZW50Iiwic2Vzc2lvbl9zdGF0ZSI6ImNmMGEzNWI1LThjZDAtNDBmYi1hYzVlLTgzNDk0OTUyZTExOSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJST0xFX1VTRVIiLCJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJlbWFpbCBwcm9maWxlIiwic2lkIjoiY2YwYTM1YjUtOGNkMC00MGZiLWFjNWUtODM0OTQ5NTJlMTE5IiwidWlkIjoiMDBteE5xOXA5Nzd0U0Ric3p2bkRPWE9iWSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwibmFtZSI6Iu2ZqeydgOuztSIsInByZWZlcnJlZF91c2VybmFtZSI6IjAwbXhfbnE5cDk3N3Rfc19kYnN6dm5fZF9vX3hfb2JfeSIsImdpdmVuX25hbWUiOiLtmansnYDrs7UiLCJmYW1pbHlfbmFtZSI6IiIsImVtYWlsIjoiZWdpcmxhc21AbmF2ZXIuY29tIn0.h92fxfNq9yS2BfMLGM6zTvUOFJDKSRz4G6ZwIWkTRk5zXrYAxZ5psdpSUPrRvLOny9dj9sSJ8Rds_DENV-v1Hf6O2LH5MTcryVFJ6dbOkK6IV68L12opveSEpfyqFH1wgKNDeomnRGKf8rge0g3q5qL7oFTDYF0ZPJm2OE-0Doo_W0yuEXcLAZ3aASo8Xrl4Xig2GZQXZwVaoYw44kFFsta2yhDjnT5WBpG8WhO-CSBC6WqN8naAPNXw9iMZSQF7YXywrUdA1xDBrTAUqsiwuRteDPuyw4x5ja5HXYedMlz2oFEDEnnGOXsMNGdlYYzyxDr6XwlGnMase67FlmxKeA';

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController _controller;

  int reloadOnce = 0;
  int timeLapse = 0;
  @override
  void initState() {
    super.initState();

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    var lastTid = "";

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) async {
            debugPrint('Page started loading: $url');
            // if (url.contains("isp")) {
            //   if (await canLaunchUrlString(
            //       'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773')) {
            //     launchUrlString(
            //         'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773');
            //   } else {
            //     print('can not launch');
            //   }
            //   // launchUrl(Uri.parse(
            //   //     'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773'));
            // }
            controller
                .runJavaScript("localStorage['hb-test-token'] = '${token}'");
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');

            var javascript = '''
      window.confirm = function (e){
        Alert.postMessage(e);
        return true;
      }
    ''';
            controller.runJavaScript(javascript);

            FlutterNativeSplash.remove();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.contains("wcardAcsAuthResult.ini")) {
              int nStart = request.url.indexOf("sKey=");
              print("lalallala => " + nStart.toString());
              String cutString =
                  request.url.substring(nStart + 15, request.url.length);
              lastTid = cutString;
              print(cutString);
            }
            if (request.url.startsWith("kb-acp") ||
                request.url.startsWith("ispmobile") ||
                request.url.contains('appCallPage.ini')) {
              try {
                // launchUrl(Uri.parse(request.url));
                const tid = "IDIMpay00020230118234009435439";
                /////             INIMX_ISP_IDIMpay00020230119004051
                //ispmobile://TID=INIMX_AISPIDIMpay00020230119003008885762
                // launchUrl(Uri.parse("ispmobile://TID=INIMX_AISP$lastTid"));
                // launchUrl(Uri.parse(
                //     "ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773"));

                if (await canLaunchUrlString(
                    'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773')) {
                  launchUrlString(
                      'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773');
                } else {
                  print('can not launch');
                }
              } catch (e, s) {
                print("error launch url");
              }
              return NavigationDecision.navigate;
            }

            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..addJavaScriptChannel('Alert',
          onMessageReceived: (JavaScriptMessage message) {
        print(message.message);
      })
      ..loadRequest(Uri.parse(
          'https://app.id-im.dev/diagnosis/consult/payment?category=D&addCode=HCC00008,HCC00009&prodCode=CRF0000003&presriptionCode=PR00000008'));

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // #enddocregion platform_features

    _controller = controller;
  }

  Future<bool> _onWillPop() async {
    final String res = await _controller
        .runJavaScriptReturningResult("window.testF()") as String;
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - timeLapse > 1000) {
      timeLapse = now;
      Fluttertoast.showToast(msg: "한번 더 누르면 앱이 종료됩니다");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
          child: Scaffold(
        backgroundColor: Colors.white,
        // appBar: AppBar(
        //   title: const Text('Flutter WebView example'),
        //   // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        //   actions: <Widget>[
        //     NavigationControls(webViewController: _controller),
        //     SampleMenu(webViewController: _controller),
        //   ],
        // ),
        body: WebViewWidget(controller: _controller),
        floatingActionButton: favoriteButton(),
      )),
    );
  }

  Widget favoriteButton() {
    return FloatingActionButton(
      onPressed: () async {
        // final String? url = await _controller.currentUrl();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Favorited $url')),
        // );
        await _controller
            .runJavaScript("localStorage['hb-test-token'] = '${token}'");
        await _controller.reload();
        // await _controller.loadRequest(Uri.parse(
        //     'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773'));
        // if (await canLaunchUrlString(
        //     'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773')) {
        //   launchUrlString(
        //       'ispmobile://TID=INIMX_AISPIDIMpay00020230119004554455773');
        // } else {
        //   print('can not launch');
        // }
      },
      child: const Icon(Icons.favorite),
    );
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
  doPostRequest,
  loadLocalFile,
  loadFlutterAsset,
  loadHtmlString,
  transparentBackground,
  setCookie,
}

class SampleMenu extends StatelessWidget {
  SampleMenu({
    super.key,
    required this.webViewController,
  });

  final WebViewController webViewController;
  late final WebViewCookieManager cookieManager = WebViewCookieManager();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuOptions>(
      key: const ValueKey<String>('ShowPopupMenu'),
      onSelected: (MenuOptions value) {
        switch (value) {
          case MenuOptions.showUserAgent:
            _onShowUserAgent();
            break;
          case MenuOptions.listCookies:
            _onListCookies(context);
            break;
          case MenuOptions.clearCookies:
            _onClearCookies(context);
            break;
          case MenuOptions.addToCache:
            _onAddToCache(context);
            break;
          case MenuOptions.listCache:
            _onListCache();
            break;
          case MenuOptions.clearCache:
            _onClearCache(context);
            break;
          case MenuOptions.navigationDelegate:
            _onNavigationDelegateExample();
            break;
          case MenuOptions.doPostRequest:
            _onDoPostRequest();
            break;
          case MenuOptions.loadLocalFile:
            _onLoadLocalFileExample();
            break;
          case MenuOptions.loadFlutterAsset:
            _onLoadFlutterAssetExample();
            break;
          case MenuOptions.loadHtmlString:
            _onLoadHtmlStringExample();
            break;
          case MenuOptions.transparentBackground:
            _onTransparentBackground();
            break;
          case MenuOptions.setCookie:
            _onSetCookie();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.showUserAgent,
          child: Text('Show user agent'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.listCookies,
          child: Text('List cookies'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.clearCookies,
          child: Text('Clear cookies'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.addToCache,
          child: Text('Add to cache'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.listCache,
          child: Text('List cache'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.clearCache,
          child: Text('Clear cache'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.navigationDelegate,
          child: Text('Navigation Delegate example'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.doPostRequest,
          child: Text('Post Request'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.loadHtmlString,
          child: Text('Load HTML string'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.loadLocalFile,
          child: Text('Load local file'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.loadFlutterAsset,
          child: Text('Load Flutter Asset'),
        ),
        const PopupMenuItem<MenuOptions>(
          key: ValueKey<String>('ShowTransparentBackgroundExample'),
          value: MenuOptions.transparentBackground,
          child: Text('Transparent background example'),
        ),
        const PopupMenuItem<MenuOptions>(
          value: MenuOptions.setCookie,
          child: Text('Set cookie'),
        ),
      ],
    );
  }

  Future<void> _onShowUserAgent() {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    return webViewController.runJavaScript(
      'Toaster.postMessage("User Agent: " + navigator.userAgent);',
    );
  }

  Future<void> _onListCookies(BuildContext context) async {
    final String cookies = await webViewController
        .runJavaScriptReturningResult('document.cookie') as String;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  Future<void> _onAddToCache(BuildContext context) async {
    await webViewController.runJavaScript(
      'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";',
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  Future<void> _onListCache() {
    return webViewController.runJavaScript('caches.keys()'
        // ignore: missing_whitespace_between_adjacent_strings
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  Future<void> _onClearCache(BuildContext context) async {
    await webViewController.clearCache();
    await webViewController.clearLocalStorage();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cache cleared.'),
    ));
  }

  Future<void> _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _onNavigationDelegateExample() {
    final String contentBase64 = base64Encode(
      const Utf8Encoder().convert(kNavigationExamplePage),
    );
    return webViewController.loadRequest(
      Uri.parse('data:text/html;base64,$contentBase64'),
    );
  }

  Future<void> _onSetCookie() async {
    await cookieManager.setCookie(
      const WebViewCookie(
        name: 'foo',
        value: 'bar',
        domain: 'httpbin.org',
        path: '/anything',
      ),
    );
    await webViewController.loadRequest(Uri.parse(
      'https://httpbin.org/anything',
    ));
  }

  Future<void> _onDoPostRequest() {
    return webViewController.loadRequest(
      Uri.parse('https://httpbin.org/post'),
      method: LoadRequestMethod.post,
      headers: <String, String>{'foo': 'bar', 'Content-Type': 'text/plain'},
      body: Uint8List.fromList('Test Body'.codeUnits),
    );
  }

  Future<void> _onLoadLocalFileExample() async {
    final String pathToIndex = await _prepareLocalFile();
    await webViewController.loadFile(pathToIndex);
  }

  Future<void> _onLoadFlutterAssetExample() {
    return webViewController.loadFlutterAsset('assets/www/index.html');
  }

  Future<void> _onLoadHtmlStringExample() {
    return webViewController.loadHtmlString(kLocalExamplePage);
  }

  Future<void> _onTransparentBackground() {
    return webViewController.loadHtmlString(kTransparentBackgroundPage);
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }

  static Future<String> _prepareLocalFile() async {
    final String tmpDir = (await getTemporaryDirectory()).path;
    final File indexFile = File(
        <String>{tmpDir, 'www', 'index.html'}.join(Platform.pathSeparator));

    await indexFile.create(recursive: true);
    await indexFile.writeAsString(kLocalExamplePage);

    return indexFile.path;
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () async {
            if (await webViewController.canGoBack()) {
              await webViewController.goBack();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No back history item')),
              );
              return;
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () async {
            if (await webViewController.canGoForward()) {
              await webViewController.goForward();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No forward history item')),
              );
              return;
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () => webViewController.reload(),
        ),
      ],
    );
  }
}
