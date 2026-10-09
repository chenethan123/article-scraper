import 'dart:convert';
import 'dart:io';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import '../models/article.dart';

/// Appends scraped articles to a Google Sheet using a service account.
///
/// Ported from the Senior Home Scraper's Python `SheetsExporter`. Same flow:
/// connect -> get or create the worksheet -> make sure row 1 has headers ->
/// skip records already in the sheet -> append the rest in rate-limited batches.
/// Only the columns differ (articles instead of facility name/email).
class SheetsExporter {
  static const List<String> headers = [
    'Published', 'Title', 'Source', 'URL', 'Relevance', 'Keywords',
  ];

  final String spreadsheetId;
  final String worksheet;
  final int batchSize;
  final Duration batchDelay;

  AutoRefreshingAuthClient? _client;
  late sheets.SheetsApi _api;

  SheetsExporter({
    required this.spreadsheetId,
    this.worksheet = 'Articles',
    this.batchSize = 100,
    this.batchDelay = const Duration(seconds: 1),
  });

  /// Authenticates with a service account key file and prepares the worksheet.
  Future<void> connect(String credentialsPath) async {
    final file = File(credentialsPath);
    if (!await file.exists()) {
      throw FileSystemException('Service account file not found', credentialsPath);
    }

    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(await file.readAsString()),
    );
    _client = await clientViaServiceAccount(
      credentials,
      [sheets.SheetsApi.spreadsheetsScope],
    );
    _api = sheets.SheetsApi(_client!);

    await _ensureWorksheet();
    await _ensureHeaders();
    print('Connected to Google Sheet (worksheet "$worksheet")');
  }

  // Sheet names with spaces or quotes must be quoted in A1 notation
  String get _range => "'${worksheet.replaceAll("'", "''")}'";

  Future<void> _ensureWorksheet() async {
    final spreadsheet = await _api.spreadsheets.get(
      spreadsheetId,
      $fields: 'sheets.properties.title',
    );
    final exists = spreadsheet.sheets
            ?.any((s) => s.properties?.title == worksheet) ??
        false;
    if (exists) return;

    await _api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(requests: [
        sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: worksheet),
          ),
        ),
      ]),
      spreadsheetId,
    );
    print('Created worksheet "$worksheet"');
  }

  Future<void> _ensureHeaders() async {
    final res = await _api.spreadsheets.values.get(spreadsheetId, '$_range!A1:F1');
    final firstRow = res.values?.firstOrNull?.map((v) => '$v').toList() ?? [];
    if (firstRow.join('|') == headers.join('|')) return;

    await _api.spreadsheets.values.update(
      sheets.ValueRange(values: [headers]),
      spreadsheetId,
      '$_range!A1:F1',
      valueInputOption: 'RAW',
    );
  }

  /// URLs already in the sheet, so repeat runs only add new articles.
  Future<Set<String>> existingUrls() async {
    final res = await _api.spreadsheets.values.get(spreadsheetId, '$_range!D2:D');
    return {
      for (final row in res.values ?? const <List<Object?>>[])
        if (row.isNotEmpty) '${row.first}',
    };
  }

  /// Appends articles that aren't in the sheet yet. Returns how many were written.
  Future<int> appendArticles(List<Article> articles) async {
    final seen = await existingUrls();
    // Set.add returns false for URLs already seen, which also dedupes this run
    final fresh = articles.where((a) => seen.add(a.url)).toList();

    if (fresh.isEmpty) {
      print('No new articles to add (all ${articles.length} already in the sheet)');
      return 0;
    }

    var written = 0;
    for (var i = 0; i < fresh.length; i += batchSize) {
      final batch = fresh.skip(i).take(batchSize).map(_toRow).toList();
      await _api.spreadsheets.values.append(
        sheets.ValueRange(values: batch),
        spreadsheetId,
        '$_range!A1',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );
      written += batch.length;
      print('Batch ${i ~/ batchSize + 1}: wrote ${batch.length} rows');

      // Small pause between batches to stay under the Sheets API rate limit
      if (i + batchSize < fresh.length) await Future.delayed(batchDelay);
    }

    print('Appended $written new articles '
        '(${articles.length - fresh.length} skipped as duplicates)');
    return written;
  }

  List<Object?> _toRow(Article a) => [
        a.publishedAt.toIso8601String(),
        a.title,
        a.source,
        a.url,
        double.parse(a.relevanceScore.toStringAsFixed(3)),
        a.keywords.join(', '),
      ];

  void close() => _client?.close();
}
