/// Feature module: sign
///
/// Hexagonal layers:
/// - domain: contracts + business rules
/// - data: API/local adapters
/// - presentation: BLoC + pages
///
/// Legacy migration note:
/// Legacy page-path has been fully removed.
/// Source of truth is this feature module.
class SignFeatureInfo {
  static const String name = 'sign';
}
