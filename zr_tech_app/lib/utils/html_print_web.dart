// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void openHtmlInvoiceForPrint(String invoiceHtml) {
  final blob = html.Blob([invoiceHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
}

