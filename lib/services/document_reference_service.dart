import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_family.dart';
import 'local_document_storage.dart';

class DocumentReferenceService {
  DocumentReferenceService({LocalDocumentStorage? storage})
    : _storage = storage ?? LocalDocumentStorage();

  static const _counterKeyPrefix = 'document_reference_counter';

  final LocalDocumentStorage _storage;

  Future<String> nextReference({
    required String documentType,
    DateTime? now,
  }) async {
    final generatedAt = now ?? DateTime.now();
    final family = resolveDocumentFamily(documentType);
    final prefix = family.referencePrefix;
    final year = generatedAt.year;
    final nextNumber = await _nextNumber(prefix: prefix, year: year);
    final reference = formatReference(
      prefix: prefix,
      year: year,
      number: nextNumber,
    );
    await _storeCounter(prefix: prefix, year: year, value: nextNumber);
    return reference;
  }

  Future<void> registerReference(String reference) async {
    final parsed = parseReference(reference);
    if (parsed == null) {
      return;
    }

    final current = await _storedCounter(
      prefix: parsed.prefix,
      year: parsed.year,
    );
    if (parsed.number > current) {
      await _storeCounter(
        prefix: parsed.prefix,
        year: parsed.year,
        value: parsed.number,
      );
    }
  }

  Future<int> _nextNumber({required String prefix, required int year}) async {
    var maxNumber = await _storedCounter(prefix: prefix, year: year);
    final projects = await _storage.loadProjects();
    for (final project in projects) {
      maxNumber = _maxReferenceNumber(
        maxNumber,
        reference: project.referenceNumber,
        prefix: prefix,
        year: year,
      );
      maxNumber = _maxReferenceNumber(
        maxNumber,
        reference: project.name,
        prefix: prefix,
        year: year,
      );
    }

    final documents = await _storage.loadDocuments();
    for (final document in documents) {
      maxNumber = _maxReferenceNumber(
        maxNumber,
        reference: document.title,
        prefix: prefix,
        year: year,
      );
      maxNumber = _maxReferenceNumber(
        maxNumber,
        reference: document.content,
        prefix: prefix,
        year: year,
      );
    }

    return maxNumber + 1;
  }

  Future<int> _storedCounter({
    required String prefix,
    required int year,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_counterKey(prefix: prefix, year: year)) ?? 0;
  }

  Future<void> _storeCounter({
    required String prefix,
    required int year,
    required int value,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_counterKey(prefix: prefix, year: year), value);
  }

  int _maxReferenceNumber(
    int current, {
    required String reference,
    required String prefix,
    required int year,
  }) {
    final expression = RegExp(
      '${RegExp.escape(prefix)}-${RegExp.escape(year.toString())}-(\\d{4})',
      caseSensitive: false,
    );
    var maxNumber = current;
    for (final match in expression.allMatches(reference)) {
      final number = int.tryParse(match.group(1) ?? '');
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }
    return maxNumber;
  }

  static String formatReference({
    required String prefix,
    required int year,
    required int number,
  }) {
    return '$prefix-$year-${number.toString().padLeft(4, '0')}';
  }

  static ParsedDocumentReference? parseReference(String reference) {
    final match = RegExp(
      r'\b(AR|PAA|PGP|RVS|FP|FIS|RAI)-(\d{4})-(\d{4})\b',
      caseSensitive: false,
    ).firstMatch(reference.trim());
    if (match == null) {
      return null;
    }
    return ParsedDocumentReference(
      prefix: match.group(1)!.toUpperCase(),
      year: int.parse(match.group(2)!),
      number: int.parse(match.group(3)!),
    );
  }

  static String _counterKey({required String prefix, required int year}) {
    return '$_counterKeyPrefix.$prefix.$year';
  }
}

class ParsedDocumentReference {
  const ParsedDocumentReference({
    required this.prefix,
    required this.year,
    required this.number,
  });

  final String prefix;
  final int year;
  final int number;
}
