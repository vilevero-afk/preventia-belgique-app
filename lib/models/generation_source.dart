enum GenerationSource {
  aiBackend('ai_backend'),
  localFallback('local_fallback'),
  error('error');

  const GenerationSource(this.value);

  final String value;
}
