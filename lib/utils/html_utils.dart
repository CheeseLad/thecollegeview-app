import 'package:html/parser.dart' as html_parser;

/// Utility class for HTML-related operations
class HtmlUtils {
  static const Map<String, String> _preservedEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&#8216;': "'", // left single quotation mark
    '&#8217;': "'", // right single quotation mark
    '&#8218;': "'", // single low-9 quotation mark
    '&#8219;': "'", // single high-reversed-9 quotation mark
    '&#8220;': '"', // left double quotation mark
    '&#8221;': '"', // right double quotation mark
    '&#8222;': '"', // double low-9 quotation mark
    '&#8223;': '"', // double high-reversed-9 quotation mark
    '&#8211;': '–', // en dash
    '&#8212;': '—', // em dash
    '&#8230;': '…', // horizontal ellipsis
    '&#8242;': "'", // prime
    '&#8243;': '"', // double prime
    '&#8364;': '€', // euro sign
    '&euro;': '€',
    '&#8482;': '™', // trademark sign
    '&#169;': '©', // copyright sign
    '&#174;': '®', // registered sign
    '&#176;': '°', // degree sign
    '&#177;': '±', // plus-minus sign
    '&#215;': '×', // multiplication sign
    '&#247;': '÷', // division sign
  };

  static final RegExp _preservedEntitiesPattern = RegExp(
    r'&(?:amp|lt|gt|quot|apos|nbsp|euro|#(?:821[126-9]|822[0-3]|8230|824[23]|8364|8482|169|174|176|177|215|247));',
  );

  static final RegExp _curlyQuotesPattern = RegExp(r'[‘’“”]');

  static String _normalizeQuotes(String input) {
    if (!input.contains(_curlyQuotesPattern)) return input;
    return input
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"');
  }

  /// Decodes HTML entities in a string
  ///
  /// This function handles both named entities (like &amp;, &lt;, &gt;)
  /// and numeric entities (like &#8216;, &#8217;, &#8220;, &#8221;)
  static String decodeHtmlEntities(String htmlString) {
    if (htmlString.isEmpty) return htmlString;

    // Fast path when no HTML tags or entities are present
    if (!htmlString.contains('&') && !htmlString.contains('<')) {
      return _normalizeQuotes(htmlString);
    }

    // Parse the HTML string and extract the text content
    // This automatically decodes all HTML entities
    final document = html_parser.parse(htmlString);
    final text = document.body?.text ?? htmlString;
    return _normalizeQuotes(text);
  }

  /// Decodes HTML entities but preserves HTML structure
  ///
  /// This is useful when you want to keep HTML formatting but decode entities
  static String decodeHtmlEntitiesPreserveTags(String htmlString) {
    if (htmlString.isEmpty || !htmlString.contains('&')) return htmlString;

    return htmlString.replaceAllMapped(
      _preservedEntitiesPattern,
      (match) => _preservedEntities[match.group(0)!] ?? match.group(0)!,
    );
  }
}
