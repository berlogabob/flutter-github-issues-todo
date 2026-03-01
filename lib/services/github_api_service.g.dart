// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubApiService)
final githubApiServiceProvider = GithubApiServiceProvider._();

final class GithubApiServiceProvider
    extends
        $FunctionalProvider<
          GitHubApiService,
          GitHubApiService,
          GitHubApiService
        >
    with $Provider<GitHubApiService> {
  GithubApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubApiServiceHash();

  @$internal
  @override
  $ProviderElement<GitHubApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GitHubApiService create(Ref ref) {
    return githubApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubApiService>(value),
    );
  }
}

String _$githubApiServiceHash() => r'ba474ac4b7114dc1804647c51f29020b53fbedb5';
