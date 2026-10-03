// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cf_servers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cfCredentials)
final cfCredentialsProvider = CfCredentialsProvider._();

final class CfCredentialsProvider
    extends $FunctionalProvider<CfCredentials, CfCredentials, CfCredentials>
    with $Provider<CfCredentials> {
  CfCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cfCredentialsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cfCredentialsHash();

  @$internal
  @override
  $ProviderElement<CfCredentials> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CfCredentials create(Ref ref) {
    return cfCredentials(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CfCredentials value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CfCredentials>(value),
    );
  }
}

String _$cfCredentialsHash() => r'65b31ddcc2c22a7d85a27e04e1dba273de587607';

@ProviderFor(cfApi)
final cfApiProvider = CfApiProvider._();

final class CfApiProvider extends $FunctionalProvider<CfApi, CfApi, CfApi>
    with $Provider<CfApi> {
  CfApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cfApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cfApiHash();

  @$internal
  @override
  $ProviderElement<CfApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CfApi create(Ref ref) {
    return cfApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CfApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CfApi>(value),
    );
  }
}

String _$cfApiHash() => r'ae9d860d5dbe7c6970c3d5bee50018fd23dc6ea0';

/// The node list of the CF site, polled; the state the CF pages read.

@ProviderFor(CfServers)
final cfServersProvider = CfServersProvider._();

/// The node list of the CF site, polled; the state the CF pages read.
final class CfServersProvider
    extends $AsyncNotifierProvider<CfServers, CfServersSnapshot> {
  /// The node list of the CF site, polled; the state the CF pages read.
  CfServersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cfServersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cfServersHash();

  @$internal
  @override
  CfServers create() => CfServers();
}

String _$cfServersHash() => r'f71c555a9f5e3a2be096c3f5858ae02a5c5dfa44';

/// The node list of the CF site, polled; the state the CF pages read.

abstract class _$CfServers extends $AsyncNotifier<CfServersSnapshot> {
  FutureOr<CfServersSnapshot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CfServersSnapshot>, CfServersSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CfServersSnapshot>, CfServersSnapshot>,
              AsyncValue<CfServersSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Fetches history rows for [id] over [hours].

@ProviderFor(cfHistory)
final cfHistoryProvider = CfHistoryFamily._();

/// Fetches history rows for [id] over [hours].

final class CfHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CfHistoryRow>>,
          List<CfHistoryRow>,
          FutureOr<List<CfHistoryRow>>
        >
    with
        $FutureModifier<List<CfHistoryRow>>,
        $FutureProvider<List<CfHistoryRow>> {
  /// Fetches history rows for [id] over [hours].
  CfHistoryProvider._({
    required CfHistoryFamily super.from,
    required ({String id, double hours}) super.argument,
  }) : super(
         retry: null,
         name: r'cfHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cfHistoryHash();

  @override
  String toString() {
    return r'cfHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<CfHistoryRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CfHistoryRow>> create(Ref ref) {
    final argument = this.argument as ({String id, double hours});
    return cfHistory(ref, id: argument.id, hours: argument.hours);
  }

  @override
  bool operator ==(Object other) {
    return other is CfHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cfHistoryHash() => r'5d9748a683df793e800d4e0f1b765a9c8b297862';

/// Fetches history rows for [id] over [hours].

final class CfHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CfHistoryRow>>,
          ({String id, double hours})
        > {
  CfHistoryFamily._()
    : super(
        retry: null,
        name: r'cfHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches history rows for [id] over [hours].

  CfHistoryProvider call({required String id, required double hours}) =>
      CfHistoryProvider._(argument: (id: id, hours: hours), from: this);

  @override
  String toString() => r'cfHistoryProvider';
}
