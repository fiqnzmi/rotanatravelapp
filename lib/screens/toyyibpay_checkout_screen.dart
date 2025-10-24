import 'dart:async';

import 'package:flutter/material.dart';
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

  Uri get _returnUri => Uri.parse(widget.returnUrl);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) =>
              setState(() => _errorMessage = error.description),
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
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _controller.reload();
                      },
                      child: const Text('Retry'),
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
