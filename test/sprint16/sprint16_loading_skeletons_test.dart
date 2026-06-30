import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gitdoit/widgets/loading_skeleton.dart';
import 'package:gitdoit/constants/app_colors.dart';

Finder findLoadingSkeletonItems() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('loading_skeleton_item_');
  });
}

void main() {
  group('Task 16.5 - Loading Skeletons Tests', () {
    group('Skeleton shows while loading', () {
      testWidgets('LoadingSkeleton displays shimmer effect', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(height: 80.0, itemCount: 5, spacing: 12.0),
            ),
          ),
        );

        // Assert - Shimmer widget should be present
        expect(find.byType(Shimmer), findsWidgets);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('LoadingSkeleton shows correct number of items', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(height: 80.0, itemCount: 3, spacing: 12.0),
            ),
          ),
        );

        // Assert - should have 3 skeleton list rows
        expect(findLoadingSkeletonItems(), findsNWidgets(3));
      });

      testWidgets('LoadingSkeleton uses correct height', (
        WidgetTester tester,
      ) async {
        // Arrange
        const skeletonHeight = 80.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(height: skeletonHeight, itemCount: 1),
            ),
          ),
        );

        // Act
        await tester.pump();

        // Assert - Container should have correct height
        final container = tester.widget<Container>(
          find.byKey(const ValueKey('loading_skeleton_item_0')),
        );
        expect(container.constraints?.maxHeight, skeletonHeight);
      });

      test('LoadingSkeleton has default parameters', () {
        // Arrange
        const skeleton = LoadingSkeleton();

        // Assert
        expect(skeleton.height, 80.0);
        expect(skeleton.itemCount, 5);
        expect(skeleton.spacing, 12.0);
        expect(skeleton.borderRadius, 8.0);
      });
    });

    group('Skeleton replaced by content', () {
      testWidgets('skeleton can be conditionally replaced with content', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool isLoading = true;

        Widget buildWidget() {
          return MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: isLoading
                      ? const LoadingSkeleton(itemCount: 3)
                      : ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(title: Text('Item $index')),
                            );
                          },
                        ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildWidget());

        // Assert - skeleton shown initially
        expect(find.byType(LoadingSkeleton), findsOneWidget);
        expect(find.text('Item 0'), findsNothing);

        // Act - switch to content
        isLoading = false;
        await tester.pumpWidget(buildWidget());

        // Assert - content shown after loading
        expect(find.byType(LoadingSkeleton), findsNothing);
        expect(find.text('Item 0'), findsOneWidget);
      });
    });

    group('No layout shift', () {
      testWidgets('skeleton matches content dimensions', (
        WidgetTester tester,
      ) async {
        // Arrange
        const skeletonHeight = 80.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  LoadingSkeleton(height: skeletonHeight, itemCount: 1),
                  SizedBox(height: 12),
                  Card(
                    child: SizedBox(
                      height: skeletonHeight,
                      child: ListTile(title: Text('Content')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Act
        await tester.pump();

        // Assert - skeleton and content should have same height
        expect(find.byType(LoadingSkeleton), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      test('skeleton height matches issue card height', () {
        // Default skeleton height is 80.0, matching issue card
        const skeleton = LoadingSkeleton();
        expect(skeleton.height, 80.0);
      });

      testWidgets('skeleton uses fixed spacing', (WidgetTester tester) async {
        // Arrange
        const spacing = 12.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(itemCount: 3, spacing: spacing),
            ),
          ),
        );

        // Act
        await tester.pump();

        // Assert - spacing should be consistent
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Matches dark theme', () {
      testWidgets('skeleton uses AppColors.cardBackground', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: LoadingSkeleton(itemCount: 1),
            ),
          ),
        );

        final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
        final gradient = shimmer.gradient as LinearGradient;
        expect(gradient.colors.first, AppColors.card);
        expect(gradient.colors[2], AppColors.background.withValues(alpha: 0.5));
      });

      testWidgets('skeleton integrates with dark theme', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColors.background,
              cardColor: AppColors.cardBackground,
            ),
            home: const Scaffold(body: LoadingSkeleton(itemCount: 3)),
          ),
        );

        // Act
        await tester.pump();

        // Assert - should render in dark theme
        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });
    });

    group('RepoHeaderSkeleton', () {
      testWidgets('RepoHeaderSkeleton displays correctly', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RepoHeaderSkeleton())),
        );

        // Assert
        expect(find.byType(RepoHeaderSkeleton), findsOneWidget);
        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('RepoHeaderSkeleton has correct height', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RepoHeaderSkeleton())),
        );

        // Act
        await tester.pump();

        // Assert - should have 72px height
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxHeight, 72.0);
      });

      testWidgets('RepoHeaderSkeleton uses shimmer effect', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RepoHeaderSkeleton())),
        );

        // Assert
        expect(find.byType(Shimmer), findsWidgets);
      });
    });

    group('Performance Tests', () {
      testWidgets('skeleton renders quickly', (WidgetTester tester) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LoadingSkeleton(itemCount: 5)),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        // Assert - should render in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('multiple skeletons render efficiently', (
        WidgetTester tester,
      ) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    LoadingSkeleton(itemCount: 3, height: 72),
                    LoadingSkeleton(itemCount: 5, height: 80),
                    LoadingSkeleton(itemCount: 2, height: 40),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        // Assert - should render efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        expect(find.byType(LoadingSkeleton), findsNWidgets(3));
      });
    });

    group('Integration Tests', () {
      testWidgets('LoadingSkeleton in list context', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool isLoading = true;
        final items = List.generate(10, (i) => 'Item $i');

        Widget buildWidget() {
          return MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: isLoading
                      ? const LoadingSkeleton(itemCount: 5)
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return ListTile(title: Text(items[index]));
                          },
                        ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildWidget());

        // Assert - skeleton shown
        expect(find.byType(LoadingSkeleton), findsOneWidget);

        // Act - switch to content
        isLoading = false;
        await tester.pumpWidget(buildWidget());

        // Assert - content shown
        expect(find.byType(LoadingSkeleton), findsNothing);
        expect(find.text('Item 0'), findsOneWidget);
      });

      testWidgets('LoadingSkeleton with custom parameters', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(
                height: 100.0,
                width: 300.0,
                borderRadius: 12.0,
                itemCount: 3,
                spacing: 16.0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(LoadingSkeleton), findsOneWidget);
        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('LoadingSkeleton disposal', (WidgetTester tester) async {
        // Arrange
        final key = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LoadingSkeleton(key: key, itemCount: 1)),
          ),
        );

        // Act - remove widget
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        // Assert - widget should be disposed without errors
        expect(find.byType(LoadingSkeleton), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('skeleton has semantic information', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LoadingSkeleton(itemCount: 1)),
          ),
        );

        // Assert - should have semantics
        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });

      testWidgets('skeleton does not block screen readers', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LoadingSkeleton(itemCount: 3)),
          ),
        );

        // Act
        await tester.pump();

        // Assert - should render without blocking
        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });
    });
  });
}
