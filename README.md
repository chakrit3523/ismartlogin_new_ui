# iSmart Login (Flutter)

เอกสารนี้เป็นคู่มือสำหรับทีมที่เข้ามาอ่าน/แก้โค้ดโปรเจกต์ `ismartlogin_new_ui` โดยเน้น:
- ดูโครงสร้างโปรเจกต์ให้เข้าใจเร็ว
- ไล่โค้ดได้ตั้งแต่ entry point ถึง feature
- ใช้ `BLoC/Cubit` ให้ถูกทางในโปรเจกต์นี้
- เทียบ `BLoC` กับ `setState` และวางแผน migration

---

## 1) ภาพรวมโปรเจกต์

- Framework: Flutter (Dart 3.x)
- State management ปัจจุบัน: `flutter_bloc` + `blocSetState` (transitional)
- DI: `get_it`
- Network: `dio` และ `http` (ยังมีทั้ง 2 แบบในโค้ด)
- โครงสร้างหลัก: `lib/src/features/<feature>/{data,domain,presentation}`

สถานะสถาปัตยกรรม (อิงโค้ดจริง ณ **4 มีนาคม 2026**):
- มี `Cubit` แยกตาม feature แล้ว: **14 ตัว**
- ยังมี `blocSetState(...)` อยู่หลายจุด: **302 จุด**
- ยังมี `setState(...)` ตรง ๆ: **6 จุด**

สรุปสั้น ๆ: โปรเจกต์อยู่ช่วง transition จากหน้าแบบ legacy ไปสู่ feature-scoped Cubit เต็มรูปแบบ

---

## 2) Quick Start

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

ถ้าเน้น iOS simulator:

```bash
flutter build ios --simulator
```

---

## 3) Source Tree (โครงสร้างที่ใช้จริง)

### 3.1 Root (ย่อ)

```text
.
|-- android/
|-- ios/
|-- assets/
|-- lib/
|   |-- main.dart
|   |-- src/
|   |   |-- ARCHITECTURE.md
|   |   |-- app/
|   |   |   |-- app.dart
|   |   |   |-- bootstrap.dart
|   |   |   `-- pages/main_page.dart
|   |   |-- core/
|   |   |   |-- di/service_locator.dart
|   |   |   |-- network/network_client.dart
|   |   |   |-- usecase/usecase.dart
|   |   |   `-- presentation/bloc/
|   |   |       |-- bloc_material.dart
|   |   |       `-- global_ui_refresh_cubit.dart
|   |   `-- features/
|   |       |-- sign/
|   |       |-- splashscreen/
|   |       |-- front/
|   |       |-- leave/
|   |       |-- history/
|   |       |-- profile/
|   |       |-- menu/
|   |       |-- map/
|   |       |-- org/
|   |       |-- managements/
|   |       |-- outside/
|   |       |-- protect/
|   |       |-- faq/
|   |       `-- contact_dev/
|   |-- widgets/
|   |-- system/
|   `-- services/
|-- test/
`-- pubspec.yaml
```

### 3.2 Feature template (รูปแบบมาตรฐานที่ควรยึด)

```text
lib/src/features/<feature>/
|-- data/
|   |-- datasources/
|   |-- models/ (หรือ model/)
|   `-- repositories/
|-- domain/
|   |-- entities/
|   |-- repositories/
|   `-- usecases/
`-- presentation/
    |-- bloc/
    `-- pages/ (และ widgets/ ถ้าจำเป็น)
```

---

## 4) สอนไล่โค้ด (Code Reading Path)

ถ้าเป็นคนใหม่ แนะนำไล่ตามลำดับนี้:

1. `lib/main.dart`
- เริ่ม app, init Firebase, เรียก `bootstrapApp()`
- ครอบ `MaterialApp` ด้วย `BlocProvider<GlobalUiRefreshCubit>`

2. `lib/src/app/bootstrap.dart` และ `lib/src/core/di/service_locator.dart`
- จุดตั้งต้น DI (`GetIt`)
- ตอนนี้ลงทะเบียน `NetworkClient` ไว้ที่นี่

3. `lib/src/features/splashscreen/presentation/pages/splashscreen_screen.dart`
- กำหนด flow เข้าแอป:
  - auto-login จาก cache
  - protect switch
  - ไป `SignInScreen` / `OrganizationScreen` / `MainPage`

4. `lib/src/features/sign/presentation/pages/signin_screen.dart`
- หน้าล็อกอินหลัก
- ปัจจุบันยังเรียก API ผ่าน `SigninFuture` โดยตรง (legacy style)

5. `lib/src/app/pages/main_page.dart`
- โครง navigation หลักหลัง login
- สลับแท็บไป `Leave`, `Front`, `History`, `Profile`, `Menu`

6. ไล่ feature ที่ต้องแก้
- เปิด `presentation/pages` ก่อน
- ตามด้วย `data/future` หรือ `data/repositories`
- ถ้าฟีเจอร์นั้นมี logic แยกแล้ว ให้เปิด `domain/usecases` และ test

ตัวอย่างที่มี use case + test ค่อนข้างชัด:
- `lib/src/features/leave/domain/usecases/leave_date_calculator.dart`
- `test/features/leave/leave_date_calculator_test.dart`

---

## 5) สอนใช้ BLoC/Cubit ในโปรเจกต์นี้

> โปรเจกต์นี้ใช้ `Cubit` เป็นหลัก (ยังไม่ใช้ `Bloc<Event, State>` แบบเต็ม)

### 5.1 โครงไฟล์ขั้นต่ำที่ควรมี

```text
presentation/bloc/
|-- xxx_state.dart
`-- xxx_cubit.dart
presentation/pages/
`-- xxx_screen.dart
```

### 5.2 ตัวอย่าง State

```dart
import 'package:equatable/equatable.dart';

class ExampleState extends Equatable {
  const ExampleState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  ExampleState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExampleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, errorMessage];
}
```

### 5.3 ตัวอย่าง Cubit

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class ExampleCubit extends Cubit<ExampleState> {
  ExampleCubit() : super(const ExampleState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // call repository/usecase here
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
```

### 5.4 ตัวอย่างผูกกับหน้า UI

```dart
BlocProvider(
  create: (_) => ExampleCubit()..loadData(),
  child: BlocConsumer<ExampleCubit, ExampleState>(
    listener: (context, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
    },
    builder: (context, state) {
      if (state.isLoading) return const CircularProgressIndicator();
      return const Text('Loaded');
    },
  ),
)
```

---

## 6) เทียบ BLoC/Cubit กับ setState

| หัวข้อ | `setState` | `BLoC/Cubit` |
|---|---|---|
| ขอบเขต | ดีมากสำหรับ state เล็กใน widget เดียว | ดีสำหรับ flow ใหญ่/หลาย async |
| การทดสอบ | ทดสอบ logic ยาก (ผูกกับ widget) | ทดสอบ state transition ได้ตรง |
| การดูแลระยะยาว | ไฟล์ยาวง่าย | แยก state/logic/UI ชัด |
| Side effects | มักกระจายในหน้าเดียว | แยก `builder`/`listener` ได้ชัด |
| เหมาะกับโปรเจกต์นี้ | ใช้เฉพาะจุดเล็ก ๆ ที่ local จริง ๆ | แนวทางหลักที่ควรไปต่อ |

สรุปสำหรับ repo นี้:
- ของใหม่ให้ทำด้วย `Cubit` ก่อนเสมอ
- `setState` ใช้ได้เฉพาะ UI local state เล็ก ๆ (เช่นเปิด/ปิด panel)
- หลีกเลี่ยงการเรียก API ตรงใน `StatefulWidget` เมื่อเริ่มแตะ logic จริง

---

## 7) Migration: จาก setState/blocSetState ไป Cubit (ทีละขั้น)

1. ระบุ state ที่หน้านั้นใช้จริง
- loading, error, data list, selected item ฯลฯ

2. สร้าง `State` และ `Cubit`
- รวม state ให้ครบก่อน แล้วค่อยย้าย method async

3. ย้าย logic async ออกจากหน้า
- API call/repository call ให้ไปอยู่ใน cubit

4. หน้า UI เปลี่ยนเป็น `BlocBuilder/BlocConsumer`
- render จาก `state` เท่านั้น
- popup/snackbar/navigation ใน `listener`

5. ลบ `blocSetState` หรือ `setState` ที่ไม่จำเป็น
- เหลือไว้เฉพาะ local UI state เล็ก ๆ ที่ไม่คุ้มย้าย

6. เพิ่ม test
- อย่างน้อย unit test ของ cubit/state transition

---

## 8) Current Gaps (สิ่งที่ควรรู้ก่อนลงมือแก้)

- หลาย feature มีไฟล์ cubit/state แล้ว แต่หน้า UI ยังไม่ได้ consume cubit โดยตรง
- บาง flow ยังเรียก `data/future/*` จาก page โดยตรง
- ในบาง feature `domain`/`repository` ยังเป็นโครง (stub) มากกว่าธุรกิจจริง
- มี helper `blocSetState(...)` สำหรับช่วง migration อยู่ที่:
  - `lib/src/core/presentation/bloc/bloc_material.dart`

หมายเหตุ:
- `blocSetState` เป็นสะพานชั่วคราว ไม่ใช่ target architecture ระยะยาว

---

## 9) Checklist ก่อนเปิด PR

1. โค้ดใหม่อยู่ใต้ `lib/src/features/<feature>` ตาม layer ที่ถูกต้อง
2. Logic async อยู่ใน cubit/usecase ไม่ใช่ยัดในหน้า
3. หน้าใช้ `BlocBuilder` หรือ `BlocConsumer` ตรง state ที่ออกแบบไว้
4. ไม่เพิ่ม `setState` ใหม่สำหรับ business flow
5. รันคำสั่งนี้ให้ผ่าน:

```bash
flutter analyze
flutter test
```

---

## 10) เอกสารที่ควรเปิดคู่กัน

- `lib/src/ARCHITECTURE.md`
- `lib/src/core/presentation/bloc/bloc_material.dart`
- `lib/src/features/*/feature_info.dart`

ถ้าจะเริ่ม refactor จริง แนะนำเริ่มจาก feature เล็กก่อน (เช่น `faq` หรือ `contact_dev`) แล้วค่อยย้าย flow ใหญ่ (`sign`, `front`, `managements`).
