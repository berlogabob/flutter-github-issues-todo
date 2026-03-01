// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(oauthService)
final oauthServiceProvider = OauthServiceProvider._();

final class OauthServiceProvider
    extends $FunctionalProvider<OAuthService, OAuthService, OAuthService>
    with $Provider<OAuthService> {
  OauthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oauthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oauthServiceHash();

  @$internal
  @override
  $ProviderElement<OAuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OAuthService create(Ref ref) {
    return oauthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OAuthService>(value),
    );
  }
}

String _$oauthServiceHash() => r'd51ffe18a2efad978ececadc7dc64c9ee65de597';
