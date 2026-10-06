import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_car_marketplace_app/ui/widgets/user/auth_dropdown_field.dart';
import 'package:online_car_marketplace_app/ui/widgets/user/auth_text_field.dart';
import 'package:online_car_marketplace_app/utils/validators/auth_validator.dart';

void main() {
  testWidgets('email form rejects invalid input then accepts correction',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
      key: formKey,
      child: AuthTextField(
          controller: controller,
          label: 'Email',
          prefixIcon: Icons.email,
          validator: AuthValidator.validateEmail),
    ))));
    await tester.enterText(find.byType(TextFormField), 'invalid');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text(AuthValidator.validateEmail('invalid')!), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'buyer@example.com');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(controller.text, 'buyer@example.com');
    expect(find.text(AuthValidator.validateEmail('invalid')!), findsNothing);
  });

  testWidgets('password masking can be toggled without losing input',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var hidden = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => AuthTextField(
        controller: controller,
        label: 'Password',
        prefixIcon: Icons.lock,
        obscureText: hidden,
        suffixIcon: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => setState(() => hidden = !hidden)),
      ),
    ))));
    await tester.enterText(find.byType(TextFormField), 'Abcdef1!');
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse);
    expect(controller.text, 'Abcdef1!');
  });

  testWidgets('dropdown requires selection and delivers chosen value',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
      key: formKey,
      child: StatefulBuilder(
          builder: (context, setState) => AuthDropdownField(
                label: 'Location',
                items: const ['Hà Nội', 'Đà Nẵng'],
                value: selected,
                onChanged: (value) => setState(() => selected = value),
                validator: (value) =>
                    value == null ? 'Choose a location' : null,
              )),
    ))));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Choose a location'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đà Nẵng').last);
    await tester.pumpAndSettle();
    expect(selected, 'Đà Nẵng');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Choose a location'), findsNothing);
  });
}
