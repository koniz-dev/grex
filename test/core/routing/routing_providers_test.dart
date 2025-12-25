import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/routing_providers.dart';

void main() {
  group('RoutingProviders', () {
    test('goRouterProvider should provide GoRouter instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      expect(router, isA<GoRouter>());
    });

    test('currentRouteProvider should provide initial route', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final currentRoute = container.read(currentRouteProvider);

      expect(currentRoute, equals('/'));
    });

    test('navigationStateProvider should provide initial navigation state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final navigationState = container.read(navigationStateProvider);

      expect(navigationState.currentRoute, equals('/'));
      expect(navigationState.pathParameters, isEmpty);
      expect(navigationState.queryParameters, isEmpty);
      expect(navigationState.canPop, isFalse);
    });
  });

  group('NavigationState', () {
    test('should create navigation state with all properties', () {
      const state = NavigationState(
        currentRoute: '/test',
        pathParameters: {'id': '123'},
        queryParameters: {'filter': 'active'},
        canPop: true,
      );

      expect(state.currentRoute, equals('/test'));
      expect(state.pathParameters, equals({'id': '123'}));
      expect(state.queryParameters, equals({'filter': 'active'}));
      expect(state.canPop, isTrue);
    });

    test('should copy navigation state with updated properties', () {
      const originalState = NavigationState(
        currentRoute: '/test',
        pathParameters: {'id': '123'},
        queryParameters: {'filter': 'active'},
        canPop: true,
      );

      final updatedState = originalState.copyWith(
        currentRoute: '/new-test',
        canPop: false,
      );

      expect(updatedState.currentRoute, equals('/new-test'));
      expect(updatedState.pathParameters, equals({'id': '123'}));
      expect(updatedState.queryParameters, equals({'filter': 'active'}));
      expect(updatedState.canPop, isFalse);
    });

    test(
      'should copy navigation state without changes when no parameters '
      'provided',
      () {
        const originalState = NavigationState(
          currentRoute: '/test',
          pathParameters: {'id': '123'},
          queryParameters: {'filter': 'active'},
          canPop: true,
        );

        final copiedState = originalState.copyWith();

        expect(copiedState.currentRoute, equals(originalState.currentRoute));
        expect(
          copiedState.pathParameters,
          equals(originalState.pathParameters),
        );
        expect(
          copiedState.queryParameters,
          equals(originalState.queryParameters),
        );
        expect(copiedState.canPop, equals(originalState.canPop));
      },
    );
  });

  group('NavigationStateNotifier', () {
    test('should initialize with default state', () {
      final notifier = NavigationStateNotifier();

      expect(notifier.state.currentRoute, equals('/'));
      expect(notifier.state.pathParameters, isEmpty);
      expect(notifier.state.queryParameters, isEmpty);
      expect(notifier.state.canPop, isFalse);
    });

    test('should update route with all parameters', () {
      final notifier = NavigationStateNotifier()
        ..updateRoute(
          route: '/test',
          pathParameters: {'id': '123'},
          queryParameters: {'filter': 'active'},
          canPop: true,
        );

      final state = notifier.state;
      expect(state.currentRoute, equals('/test'));
      expect(state.pathParameters, equals({'id': '123'}));
      expect(state.queryParameters, equals({'filter': 'active'}));
      expect(state.canPop, isTrue);
    });

    test('should update route with partial parameters', () {
      final notifier = NavigationStateNotifier()
        ..updateRoute(
          route: '/test',
          pathParameters: {'id': '123'},
        );

      final state = notifier.state;
      expect(state.currentRoute, equals('/test'));
      expect(state.pathParameters, equals({'id': '123'}));
      expect(state.queryParameters, isEmpty);
      expect(state.canPop, isFalse);
    });

    test('should update canPop independently', () {
      final notifier = NavigationStateNotifier()..updateCanPop(canPop: true);

      expect(notifier.state.currentRoute, equals('/'));
      expect(notifier.state.canPop, isTrue);

      notifier.updateCanPop(canPop: false);

      expect(notifier.state.canPop, isFalse);
    });

    test('should maintain state across multiple updates', () {
      final notifier = NavigationStateNotifier()
        ..updateRoute(
          route: '/first',
          pathParameters: {'id': '1'},
        );

      final state = notifier.state;
      expect(state.currentRoute, equals('/first'));
      expect(state.pathParameters, equals({'id': '1'}));

      notifier.updateRoute(
        route: '/second',
        pathParameters: {'id': '2'},
        queryParameters: {'view': 'details'},
      );

      expect(notifier.state.currentRoute, equals('/second'));
      expect(notifier.state.pathParameters, equals({'id': '2'}));
      expect(notifier.state.queryParameters, equals({'view': 'details'}));
    });

    test('should work with ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(navigationStateProvider.notifier)
          .updateRoute(
            route: '/test',
            pathParameters: {'id': '123'},
          );

      final state = container.read(navigationStateProvider);

      expect(state.currentRoute, equals('/test'));
      expect(state.pathParameters, equals({'id': '123'}));
    });

    test('should notify listeners on state changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var notificationCount = 0;
      container.listen(
        navigationStateProvider,
        (previous, next) {
          notificationCount++;
        },
      );

      container.read(navigationStateProvider.notifier)
        ..updateRoute(route: '/test1')
        ..updateRoute(route: '/test2')
        ..updateCanPop(canPop: true);

      expect(notificationCount, equals(3));
    });
  });
}
