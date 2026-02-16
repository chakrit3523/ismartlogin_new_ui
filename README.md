# iConnect Flutter App

Package ID: `th.co.cityvariety.iconnect`

README นี้เขียนแบบ "สอนไอปาร์ค" โดยเฉพาะ
เป้าหมายคืออ่านจบแล้วรู้ทันทีว่า:
- โปรเจ็กต์นี้จัดโครงสร้างยังไง
- เวลาแก้โค้ดต้องเริ่มตรงไหน
- อะไรทำได้ / อะไรห้ามทำ
- ก่อนส่งงานต้องเช็กอะไรบ้าง

---

## เริ่มจากภาพใหญ่ (แบบง่ายที่สุด)

แอปนี้ใช้แนว **Hexagonal + BLoC/Cubit**

ให้จำแบบสั้นๆ:
- `presentation` = หน้าจอ + widget + state ของ UI
- `domain` = กฎธุรกิจล้วนๆ
- `application` = flow/use case ที่สั่งงานหลายชิ้น
- `infrastructure` = ของที่คุยโลกจริง (API, DB, Firebase, WebSocket)

ถ้ายังจำไม่ได้ ให้ใช้ประโยคนี้:
- `presentation` "แสดงผล"
- `domain` "ตัดสินถูกผิด"
- `application` "ประสานงาน"
- `infrastructure` "ลงมือคุยระบบภายนอก"

---

## ถ้าพึ่งเข้ามาวันแรก ให้ทำ 5 ขั้นตอนนี้

1. อ่าน `lib/src/ARCHITECTURE.md` ก่อน 1 รอบ
2. อ่าน `lib/src/core/di/app_composition_root.dart`
3. อ่าน `lib/src/features/app/app_feature_module.dart`
4. รันคำสั่งนี้ให้ผ่าน

```bash
flutter pub get
flutter analyze lib
flutter test
flutter build ios --simulator
```

5. เปิดดูโฟลเดอร์ `lib/src/features/app/presentation/frontpage/pages/news_feed/` เพื่อเข้าใจรูปแบบการแยกไฟล์ที่ทีมใช้

---

## โครงสร้างที่ต้องรู้ (ของจริงในโปรเจ็กต์)

```text
lib/
  main.dart
  src/
    ARCHITECTURE.md
    core/
      app/
      di/
        app_composition_root.dart
        feature_module.dart
      routing/
        app_route_paths.dart
        app_route_entry.dart
        app_router.dart
      presentation/state/
        bloc_state.dart
        ui_refresh_cubit.dart
        ui_refresh_scope.dart

    features/
      app/
        app_feature_module.dart
        presentation/
          frontpage/
            pages/
              news_feed/
              rsvp/
              survey/
            news_card/
            news_modal/
            navigation/
            gallery/
            state/
            widgets/
            legacy/
          post/
          post_edit/
          user/
          banner/
          approved/
          gallery/
          services/
          ...
```

> หมายเหตุ: ตอนนี้โค้ดเดิมถูกย้ายมาอยู่ใต้ `lib/src/features/app/presentation/*` แล้ว

---

## Route + DI ทำงานยังไง (จำให้ขึ้นใจ)

### จุดรวมศูนย์มีจุดเดียว
- `lib/src/core/di/app_composition_root.dart`

ไฟล์นี้ทำหน้าที่:
- รวมทุก `FeatureModule`
- รวม `blocProviders`
- รวม `routes`
- ปล่อยเข้า `MaterialApp` ผ่าน `AppRouter`

### feature module ของโปรเจ็กต์นี้
- `lib/src/features/app/app_feature_module.dart`

ตอนนี้ module นี้ลงทะเบียน provider หลัก เช่น:
- `NewsStateManager`
- `UserProvider`

และ route หลัก เช่น:
- splash
- frontpage
- maingroup
- news detail
- gallery detail

### กฎเหล็ก
- ห้ามลง route/provider กระจัดกระจายในไฟล์อื่นแบบ ad-hoc
- ถ้าจะเพิ่ม route/provider ใหม่ ให้เพิ่มผ่าน `FeatureModule` แล้วค่อยให้ `AppCompositionRoot` รวม

---

## State Management ที่ทีมใช้จริง

### มาตรฐานปัจจุบัน
- ใช้ `Bloc`/`Cubit` เป็นหลัก
- ใช้ `context.read<T>()` สำหรับเรียก instance
- ใช้ `BlocBuilder` / `BlocListener` / `BlocConsumer` สำหรับฟัง state

### แล้ว `StatefulWidget` เดิมล่ะ?
ยังใช้ได้ แต่ต้องใช้สะพานนี้:
- base class: `BlocState<T>`
- แทน `setState(...)` ด้วย `blocSetState(...)`

`blocSetState(...)` ทำ 2 อย่าง:
1. อัปเดต local state ในหน้าเดิม
2. ส่งสัญญาณผ่าน `UiRefreshCubit` เพื่อให้ flow กลางสอดคล้อง

ไฟล์อ้างอิง:
- `lib/src/core/presentation/state/bloc_state.dart`
- `lib/src/core/presentation/state/ui_refresh_cubit.dart`

---

## โครงสร้างไฟล์ใน 1 หน้า ควรเป็นแบบไหน

เวลาไฟล์เริ่มยาว ให้แตกแบบนี้:

- `xxx.dart` หรือ `xxx_page.dart` = shell หลัก (State + lifecycle + wiring)
- `xxx_actions.dart` = event / side-effect / call service
- `xxx_widgets.dart` = widget tree
- `xxx_view.dart` = ถ้าต้องการแยก UI ทั้งหน้า
- `xxx_section_2.dart`, `xxx_section_3.dart` = แยกก้อนยาวแบบ incremental โดยไม่เปลี่ยน behavior

ตัวอย่างในโปรเจ็กต์:
- `news_card.dart` + `news_card_*_section_2/3/4.dart`
- `news_modal_view.dart` + `news_modal_view_layout.dart`
- `setting_forms.dart` + `setting_forms_section_2.dart` + `setting_forms_section_3.dart`
- `otpforpass.dart` + `otpforpass_view.dart`

---

## ถ้าจะเพิ่ม feature ใหม่ ทำตามนี้ทีละข้อ

1. สร้างโครงสร้าง feature

```text
lib/src/features/<your_feature>/
  domain/
  application/
  infrastructure/
  presentation/
```

2. สร้าง `<your_feature>_feature_module.dart` แล้ว implement `FeatureModule`
3. เพิ่ม `blocProviders` และ `routes` ใน module นั้น
4. ไป register module ที่ `app_composition_root.dart`
5. เพิ่ม test อย่างน้อย 3 กลุ่ม
- route behavior
- module registration
- bloc/cubit state behavior

---

## Checklist ก่อนส่งงาน

- โค้ดใหม่อยู่ใต้ `lib/src` เท่านั้น
- เพิ่ม route/provider ผ่าน module เท่านั้น
- state ใหม่ใช้ BLoC/Cubit
- ไฟล์ยาวเกินเหตุควรถูกแยก
- รันครบ:

```bash
flutter analyze lib
flutter test
flutter build ios --simulator
```

---

## Troubleshooting ที่เจอบ่อย

### 1) iOS build เจอ `webview_flutter_wkwebview_privacy.bundle` หาย

อาการตัวอย่าง:
- `lstat ... webview_flutter_wkwebview_privacy.bundle: No such file or directory`

ลองตามลำดับนี้:

```bash
flutter pub get
flutter clean
flutter build ios --simulator
```

ถ้ายังไม่หาย:
1. ลบ `ios/Pods`
2. ลบ `ios/Podfile.lock`
3. เข้าโฟลเดอร์ `ios` แล้ว `pod install`
4. เปิด `ios/Runner.xcworkspace` แล้วลอง Build ใน Xcode

---

## แบบเดิม vs แบบใหม่ (อธิบายให้เด็กฝึกงาน)

### แบบเดิม (Provider/setState-centric)
- หน้าเดียวมีทั้ง UI + API + logic รวมกัน
- ไฟล์ยาวมาก แก้ยาก กลัวพัง
- เทสต์ยาก เพราะ logic ผูกกับ widget lifecycle เยอะ

### แบบใหม่ (Hexagonal + BLoC/Cubit)
- แยกหน้าที่ชัด
- อ่านง่าย แก้เฉพาะจุดง่าย
- เขียนเทสต์ง่ายกว่า
- route/DI ชัดเจน มีจุดรวมเดียว

### เทียบ `setState` แบบตรงๆ
- `setState` ดีสำหรับ state เล็กๆ ใน widget เดียว
- แต่พอ flow ใหญ่ (หลาย API/หลาย step/หลายหน้า) จะซับซ้อนเร็ว
- ในโปรเจ็กต์นี้จึงใช้ BLoC/Cubit เป็นหลัก และใช้ `blocSetState` เป็นสะพานตอน migration

### เทียบกับ `Provider`
- `Provider` ดีสำหรับ dependency/state เบาๆ
- แต่ flow ใหญ่ต้องออกกติกาเองเยอะ
- `BLoC/Cubit` ชัดกว่าในงานที่มี state transition เยอะ

---

## สถานะปัจจุบันของโปรเจ็กต์ (อัปเดตล่าสุด)

- โครงสร้างหลักย้ายเข้า `lib/src` แล้ว
- มีการแตกไฟล์ presentation ต่อเนื่องทั้งโปรเจ็กต์
- ปัจจุบัน **ไม่มีไฟล์ใน `presentation` ที่เกิน 600 บรรทัด**
- คำสั่งตรวจหลักผ่าน:
  - `flutter analyze lib`
  - `flutter test`
  - `flutter build ios --simulator`

### งานที่ยังทำต่อได้ (ถ้าจะเก็บสุด)
- ลดไฟล์ช่วง 550-599 บรรทัด ให้ลงต่ำกว่า 500 ทั้งหมด
- ทยอยย้าย/ปิด `frontpage/legacy/ultrasmooth.dart` ให้หมด

---

## สรุปสั้นที่สุดสำหรับคนรีบ

ถ้าจำได้แค่ 4 ข้อนี้พอ:

1. เพิ่มโค้ดใหม่ใต้ `lib/src` เท่านั้น
2. route/provider ลงผ่าน `FeatureModule` เท่านั้น
3. state ใหม่ใช้ BLoC/Cubit
4. ก่อนส่งงานต้องผ่าน `analyze + test + ios simulator build`
