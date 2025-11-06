import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ToyyibpayCheckoutScreen extends StatefulWidget {
  const ToyyibpayCheckoutScreen({
    super.key,
    required this.paymentUrl,
    required this.returnUrl,
    this.title = 'Toyyibpay Checkout',
  });

  final Uri paymentUrl;
  final String returnUrl;
  final String title;

  @override
  State<ToyyibpayCheckoutScreen> createState() =>
      _ToyyibpayCheckoutScreenState();
}

class _ToyyibpayCheckoutScreenState extends State<ToyyibpayCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _failedUrl;
  String? _currentUrl;
  bool _autoLaunchedExternal = false;

  Uri get _returnUri => Uri.parse(widget.returnUrl);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_buildUserAgent())
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _currentUrl = url;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _failedUrl = null;
            });
          },
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            // -999 is NSURLErrorCancelled on iOS, which fires during legitimate redirects.
            if (Platform.isIOS && error.errorCode == -999) {
              return;
            }
            setState(() {
              final buffer = StringBuffer(error.description);
              buffer.write(' (code: ${error.errorCode})');
              final type = error.errorType.toString();
              if (type.isNotEmpty) {
                buffer.write(' • ${type.split('.').last}');
              }
              _errorMessage = buffer.toString();
              _failedUrl = _currentUrl;
              _isLoading = false;
            });
            // Some FPX bank pages block Android WebView. Fallback to external browser automatically once.
            if (Platform.isAndroid && !_autoLaunchedExternal) {
              _autoLaunchedExternal = true;
              // Give the UI a tick to settle before launching.
              scheduleMicrotask(() => _openExternally());
            }
          },
          onNavigationRequest: (request) {
            if (_matchesReturnUrl(request.url)) {
              _handleCompletion(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.paymentUrl);
  }

  bool _matchesReturnUrl(String url) {
    final target = _returnUri;
    final current = Uri.parse(url);

    if (target.scheme != current.scheme) return false;
    if (target.host != current.host) return false;
    if (target.path.isEmpty) return true;
    return current.path.startsWith(target.path);
  }

  Future<void> _handleCompletion(Uri result) async {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  String _buildUserAgent() {
    final baseChromeVersion = '126.0.0.0';
    final osVersion = Platform.isAndroid ? 'Android ${Platform.version.split(' ').first}' : Platform.operatingSystemVersion;
    return 'Mozilla/5.0 (Linux; ${Platform.isAndroid ? 'Android' : 'X11'} $osVersion) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$baseChromeVersion Mobile Safari/537.36';
  }

  Future<void> _openExternally() async {
    final target = _failedUrl ?? _currentUrl ?? widget.paymentUrl.toString();
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _controller.reload();
                      },
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: _openExternally,
                      label: const Text('Open in browser'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
