// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_requests.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which tab the app should be showing.
///
/// Set by anything that opens something living in a tab, and cleared by the
/// home page once it has moved. A request rather than a command because the
/// home page owns its page controller and the animation that goes with it.

@ProviderFor(HomeTabRequest)
final homeTabRequestProvider = HomeTabRequestProvider._();

/// Which tab the app should be showing.
///
/// Set by anything that opens something living in a tab, and cleared by the
/// home page once it has moved. A request rather than a command because the
/// home page owns its page controller and the animation that goes with it.
final class HomeTabRequestProvider
    extends $NotifierProvider<HomeTabRequest, AppTab?> {
  /// Which tab the app should be showing.
  ///
  /// Set by anything that opens something living in a tab, and cleared by the
  /// home page once it has moved. A request rather than a command because the
  /// home page owns its page controller and the animation that goes with it.
  HomeTabRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTabRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTabRequestHash();

  @$internal
  @override
  HomeTabRequest create() => HomeTabRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppTab? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppTab?>(value),
    );
  }
}

String _$homeTabRequestHash() => r'15b255ea94725952546f0e153b23660ef8cb1756';

/// Which tab the app should be showing.
///
/// Set by anything that opens something living in a tab, and cleared by the
/// home page once it has moved. A request rather than a command because the
/// home page owns its page controller and the animation that goes with it.

abstract class _$HomeTabRequest extends $Notifier<AppTab?> {
  AppTab? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppTab?, AppTab?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppTab?, AppTab?>,
              AppTab?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which tab is on screen right now.

@ProviderFor(CurrentHomeTab)
final currentHomeTabProvider = CurrentHomeTabProvider._();

/// Which tab is on screen right now.
final class CurrentHomeTabProvider
    extends $NotifierProvider<CurrentHomeTab, AppTab?> {
  /// Which tab is on screen right now.
  CurrentHomeTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentHomeTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentHomeTabHash();

  @$internal
  @override
  CurrentHomeTab create() => CurrentHomeTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppTab? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppTab?>(value),
    );
  }
}

String _$currentHomeTabHash() => r'af235edea49c8cf180a96ad5f182d2c18aaf6fe2';

/// Which tab is on screen right now.

abstract class _$CurrentHomeTab extends $Notifier<AppTab?> {
  AppTab? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppTab?, AppTab?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppTab?, AppTab?>,
              AppTab?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The tab that is drawing something the window's chrome is in the way of.
///
/// One thing sets it: the globe. A sphere fills the column it is given, and the
/// bar over it and the navigation under it are two rows of controls around a
/// picture that *is* the page — so while it is up the tab takes the window and
/// carries its own way out.
///
/// Which tab rather than a bare flag, because a tab is kept alive behind the
/// others: the server tab goes on drawing a globe while somebody reads
/// something else, and the chrome has to be back for that one.

@ProviderFor(ImmersiveTab)
final immersiveTabProvider = ImmersiveTabProvider._();

/// The tab that is drawing something the window's chrome is in the way of.
///
/// One thing sets it: the globe. A sphere fills the column it is given, and the
/// bar over it and the navigation under it are two rows of controls around a
/// picture that *is* the page — so while it is up the tab takes the window and
/// carries its own way out.
///
/// Which tab rather than a bare flag, because a tab is kept alive behind the
/// others: the server tab goes on drawing a globe while somebody reads
/// something else, and the chrome has to be back for that one.
final class ImmersiveTabProvider
    extends $NotifierProvider<ImmersiveTab, AppTab?> {
  /// The tab that is drawing something the window's chrome is in the way of.
  ///
  /// One thing sets it: the globe. A sphere fills the column it is given, and the
  /// bar over it and the navigation under it are two rows of controls around a
  /// picture that *is* the page — so while it is up the tab takes the window and
  /// carries its own way out.
  ///
  /// Which tab rather than a bare flag, because a tab is kept alive behind the
  /// others: the server tab goes on drawing a globe while somebody reads
  /// something else, and the chrome has to be back for that one.
  ImmersiveTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'immersiveTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$immersiveTabHash();

  @$internal
  @override
  ImmersiveTab create() => ImmersiveTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppTab? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppTab?>(value),
    );
  }
}

String _$immersiveTabHash() => r'ab35284389168023d991281a62a018147269ca3d';

/// The tab that is drawing something the window's chrome is in the way of.
///
/// One thing sets it: the globe. A sphere fills the column it is given, and the
/// bar over it and the navigation under it are two rows of controls around a
/// picture that *is* the page — so while it is up the tab takes the window and
/// carries its own way out.
///
/// Which tab rather than a bare flag, because a tab is kept alive behind the
/// others: the server tab goes on drawing a globe while somebody reads
/// something else, and the chrome has to be back for that one.

abstract class _$ImmersiveTab extends $Notifier<AppTab?> {
  AppTab? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppTab?, AppTab?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppTab?, AppTab?>,
              AppTab?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A server waiting to be opened on the server tab.
///
/// A request rather than a call for two reasons. The tab may not exist yet —
/// tabs are built when first visited — and only the tab knows whether opening
/// something means selecting it beside the list or pushing a page over it.

@ProviderFor(ServerDetailRequest)
final serverDetailRequestProvider = ServerDetailRequestProvider._();

/// A server waiting to be opened on the server tab.
///
/// A request rather than a call for two reasons. The tab may not exist yet —
/// tabs are built when first visited — and only the tab knows whether opening
/// something means selecting it beside the list or pushing a page over it.
final class ServerDetailRequestProvider
    extends $NotifierProvider<ServerDetailRequest, String?> {
  /// A server waiting to be opened on the server tab.
  ///
  /// A request rather than a call for two reasons. The tab may not exist yet —
  /// tabs are built when first visited — and only the tab knows whether opening
  /// something means selecting it beside the list or pushing a page over it.
  ServerDetailRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverDetailRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverDetailRequestHash();

  @$internal
  @override
  ServerDetailRequest create() => ServerDetailRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$serverDetailRequestHash() =>
    r'c0434cde59f389fa9ffa2f6054adf07b2f9244e5';

/// A server waiting to be opened on the server tab.
///
/// A request rather than a call for two reasons. The tab may not exist yet —
/// tabs are built when first visited — and only the tab knows whether opening
/// something means selecting it beside the list or pushing a page over it.

abstract class _$ServerDetailRequest extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
