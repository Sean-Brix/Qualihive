import 'dart:async';
import 'dart:convert';

import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/application/auth_providers.dart';
import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/domain/batch.dart';
import '../../monitoring/domain/sensor_reading.dart';
import '../data/csv_writer.dart';
import '../data/pdf_report_builder.dart';

part 'report_providers.g.dart';

/// Export and sharing actions — specification §9.
///
/// PDFs go through `printing`, which opens the platform print/share sheet, so
/// the same call covers "print it" and "send it to someone". CSVs go through
/// `share_plus` as an in-memory file: the artefact is generated on demand and
/// never written to a directory the app would then have to clean up.
@riverpod
class ReportController extends _$ReportController {
  @override
  FutureOr<void> build() {}

  /// Opens the print/share sheet with a one-batch quality report.
  Future<void> shareBatchPdf(Batch batch) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final bytes = await PdfReportBuilder.batchReport(
        batch,
        account: ref.read(sessionControllerProvider).value,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'qualihive-${batch.code}.pdf',
      );
    });
  }

  Future<void> shareBatchCsv(Batch batch, List<SensorReading> readings) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final rows = readings.isEmpty
          ? await ref.read(readingRepositoryProvider).getForBatch(batch.code)
          : readings;

      await _shareText(
        CsvWriter.readings(rows),
        filename: 'qualihive-${batch.code}-readings.csv',
        subject: 'Qualihive readings ${batch.code}',
      );
    });
  }

  /// Every batch as one summary sheet.
  Future<void> shareAllBatchesCsv() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final batches = await ref.read(batchRepositoryProvider).getAll();

      await _shareText(
        CsvWriter.batches(batches),
        filename: 'qualihive-batches.csv',
        subject: 'Qualihive batch summary',
      );
    });
  }

  /// The raw reading log, capped so a long-running device does not try to
  /// build a share payload out of the whole table.
  Future<void> shareAllReadingsCsv({int limit = 5000}) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final readings =
          await ref.read(readingRepositoryProvider).getRecent(limit: limit);

      await _shareText(
        // getRecent is newest-first; a log reads oldest-first.
        CsvWriter.readings(readings.reversed.toList(growable: false)),
        filename: 'qualihive-readings.csv',
        subject: 'Qualihive reading log',
      );
    });
  }

  Future<void> _shareText(
    String content, {
    required String filename,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: <XFile>[
          XFile.fromData(
            utf8.encode(content),
            mimeType: 'text/csv',
            name: filename,
          ),
        ],
        fileNameOverrides: <String>[filename],
      ),
    );
  }
}
