import 'package:flutter_test/flutter_test.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:ismart_login/src/core/presentation/bloc/global_ui_refresh_cubit.dart';

void main() {
  testWidgets('GlobalUiRefreshCubit can rebuild widget tree',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<GlobalUiRefreshCubit>(
        create: (_) => GlobalUiRefreshCubit(),
        child: MaterialApp(
          home: Scaffold(
            body: BlocBuilder<GlobalUiRefreshCubit, int>(
              builder: (context, state) {
                return Text('state:$state', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('state:0'), findsOneWidget);

    tester.element(find.byType(Text)).read<GlobalUiRefreshCubit>().refresh();
    await tester.pump();

    expect(find.text('state:1'), findsOneWidget);
  });
}
