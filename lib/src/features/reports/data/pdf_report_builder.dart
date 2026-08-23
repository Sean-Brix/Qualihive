import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../auth/domain/account.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/quality_spec.dart';

/// Builds the printable quality-assessment report of specification §9.
///
/// The layout follows the three levels of §8 in order — parameter results,
/// then the overall assessment, then the recommendation — so the page reads
/// the same way the app does, and a printout can stand as the batch record.
abstract final class PdfReportBuilder {
  static final DateFormat _timestamp = DateFormat('d MMM y, HH:mm');

  static const PdfColor _accent = PdfColor.fromInt(0xFFE8A33D);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1E1B16);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6C665C);
  static const PdfColor _rule = PdfColor.fromInt(0xFFDDD6CC);

  static Future<Uint8List> batchReport(Batch batch, {Account? account}) async {
    final document = pw.Document(title: 'Qualihive report ${batch.code}');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (context) => <pw.Widget>[
          _header(batch, account),
          pw.SizedBox(height: 20),
          _verdict(batch),
          pw.SizedBox(height: 20),
          _sessionTable(batch),
          pw.SizedBox(height: 20),
          _resultsTable(batch),
          pw.SizedBox(height: 20),
          if (batch.notes != null && batch.notes!.trim().isNotEmpty) ...<pw.Widget>[
            _section('Notes'),
            pw.SizedBox(height: 6),
            pw.Text(_safe(batch.notes!), style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
          ],
          _disclaimer(),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(Batch batch, Account? account) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'Qualihive',
                  style: const pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(
                  'Honey Quality Assessment Report',
                  style: const pw.TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Text(
                  _safe(batch.code),
                  style: const pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated ${_timestamp.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
                if (account != null)
                  pw.Text(
                    _safe(account.farmName ?? account.displayName),
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: _accent),
      ],
    );
  }

  /// Levels 2 and 3 of §8, given the top of the page because they are the
  /// point of the report.
  static pw.Widget _verdict(Batch batch) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'OVERALL ASSESSMENT',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            batch.assessment.label,
            style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (batch.summary != null) ...<pw.Widget>[
            pw.SizedBox(height: 2),
            pw.Text(
              _safe(batch.summary!),
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'RECOMMENDED ACTION',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            batch.recommendation.label,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _safe(batch.recommendation.detail),
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sessionTable(Batch batch) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _section('Batch record'),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(2),
          },
          children: <pw.TableRow>[
            _kv('Batch ID', batch.code),
            _kv('Started', _timestamp.format(batch.startedAt)),
            _kv(
              'Ended',
              batch.endedAt == null
                  ? 'Still running'
                  : _timestamp.format(batch.endedAt!),
            ),
            _kv('Readings recorded', '${batch.readingCount}'),
            _kv('Filtration stage', batch.stage.label),
            _kv('Machine status', batch.machineStatus.label),
            _kv(
              'Machine',
              batch.deviceName ?? batch.deviceId ?? 'Not recorded',
            ),
            _kv(
              'Quantity processed',
              batch.weightKg == null
                  ? 'Not recorded'
                  : '${batch.weightKg!.toStringAsFixed(2)} kg',
            ),
          ],
        ),
      ],
    );
  }

  /// Level 1 of §8.
  static pw.Widget _resultsTable(Batch batch) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _section('Parameter results'),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _rule, width: 0.5),
          headerStyle: const pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF6F1E8),
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: const <int, pw.Alignment>{
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
          headers: const <String>['Parameter', 'Value', 'Accepted range', 'Result'],
          data: <List<String>>[
            for (final result in batch.results)
              <String>[
                _safe(
                  result.label.isEmpty ? result.parameter.name : result.label,
                ),
                result.value == null
                    ? '-'
                    : _safe(
                        '${result.value!.toStringAsFixed(2)} ${result.unit}'
                            .trim(),
                      ),
                result.status == QualityStatus.unrated
                    ? 'Not graded'
                    : _safe(result.rangeLabel),
                result.status.label,
              ],
          ],
        ),
      ],
    );
  }

  /// Specification §12 rules out authenticity claims from this sensor set, so
  /// every printed report says what the assessment does and does not cover.
  static pw.Widget _disclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F1E8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'This report assesses the batch against the quality reference values '
        'configured in the application. It is not a statement of honey '
        'authenticity or purity, and it does not replace laboratory testing. '
        'Reference values should be confirmed with the researchers before the '
        'report is relied upon.',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  /// Rewrites the few characters the built-in PDF fonts cannot draw.
  ///
  /// Helvetica and its siblings are encoded as WinAnsi, which covers the
  /// degree sign and the dashes but not the comparison signs the range labels
  /// use. Those would print as blanks, so a one-sided range reads `<= 40 °C`
  /// in the PDF even though the app shows it with a proper glyph. Embedding a
  /// Unicode font is the alternative, but the app has to work offline and
  /// shipping a font file is a change for the researchers to approve.
  static String _safe(String text) => text
      .replaceAll('≤', '<=')
      .replaceAll('≥', '>=')
      .replaceAll('−', '-')
      .replaceAll('…', '...');

  static pw.Widget _section(String title) => pw.Text(
        title.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.6,
        ),
      );

  static pw.TableRow _kv(String label, String value) {
    return pw.TableRow(
      children: <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(_safe(value), style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }
}
