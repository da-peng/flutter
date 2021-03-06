// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Dialog is scrollable', (WidgetTester tester) async {
    bool didPressOk = false;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          content: new Container(
                            height: 5000.0,
                            width: 300.0,
                            color: Colors.green[500],
                          ),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                didPressOk = true;
                              },
                              child: const Text('OK')
                            )
                          ],
                        );
                      },
                    );
                  }
                )
              );
            }
          )
        )
      )
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    expect(didPressOk, false);
    await tester.tap(find.text('OK'));
    expect(didPressOk, true);
  });

  testWidgets('Dialog background color', (WidgetTester tester) async {

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[ ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final StatefulElement widget = tester.element(find.byType(Material).last);
    final Material materialWidget = widget.state.widget;
    //first and second expect check that the material is the dialog's one
    expect(materialWidget.type, MaterialType.card);
    expect(materialWidget.elevation, 24);
    expect(materialWidget.color, Colors.grey[800]);
  });

  testWidgets('Simple dialog control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    final Future<int> result = showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            new SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 42);
              },
              child: const Text('First option'),
            ),
            const SimpleDialogOption(
              child: Text('Second option'),
            ),
          ],
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('First option'));

    expect(await result, equals(42));
  });

  testWidgets('Barrier dismissible', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return new Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog1'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsNothing);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog2'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

    // Tap on the barrier, which shouldn't do anything this time.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

  });

  testWidgets('Dialog hides underlying semantics tree', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    const String buttonText = 'A button covered by dialog overlay';
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: Center(
            child: RaisedButton(
              onPressed: null,
              child: Text(buttonText),
            ),
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: buttonText));

    final BuildContext context = tester.element(find.text(buttonText));

    const String alertText = 'A button in an overlay alert';
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(title: Text(alertText));
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(label: alertText));
    expect(semantics, isNot(includesNodeWith(label: buttonText)));

    semantics.dispose();
  });

  testWidgets('Dialogs removes MediaQuery padding and view insets', (WidgetTester tester) async {
    BuildContext outerContext;
    BuildContext routeContext;
    BuildContext dialogContext;

    await tester.pumpWidget(new Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: new MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
          viewInsets: EdgeInsets.only(left: 25.0, bottom: 75.0),
        ),
        child: new Navigator(
          onGenerateRoute: (_) {
            return new PageRouteBuilder<void>(
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                outerContext = context;
                return new Container();
              },
            );
          },
        ),
      ),
    ));

    showDialog<void>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        routeContext = context;
        return new Dialog(
          child: new Builder(
            builder: (BuildContext context) {
              dialogContext = context;
              return const Placeholder();
            },
          ),
        );
      },
    );

    await tester.pump();

    expect(MediaQuery.of(outerContext).padding, const EdgeInsets.all(50.0));
    expect(MediaQuery.of(routeContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(dialogContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(outerContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(routeContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(dialogContext).viewInsets, EdgeInsets.zero);
  });

  testWidgets('Dialog widget insets by viewInsets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0),
        ),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(Placeholder)),
      new Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        ),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect( // no change because this is an animation
      tester.getRect(find.byType(Placeholder)),
      new Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect( // animation finished
      tester.getRect(find.byType(Placeholder)),
      new Rect.fromLTRB(40.0, 24.0, 800.0 - 40.0, 600.0 - 24.0),
    );
  });

  testWidgets('Dialog widget contains route semantics from title', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(semantics, isNot(includesNodeWith(
        label: 'Title',
        flags: <SemanticsFlag>[SemanticsFlag.namesRoute]
    )));

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      label: 'Title',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    ));

    semantics.dispose();
  });
}
