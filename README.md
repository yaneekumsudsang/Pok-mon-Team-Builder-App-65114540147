## วิธีรันโปรเจกต์

### 1) เตรียมเครื่อง

* ติดตั้ง **Flutter SDK** และตรวจสอบด้วย `flutter doctor`
* ติดตั้ง Android Studio/Xcode ถ้าจะรันบนมือถือ หรือเปิด web support (`flutter config --enable-web`) ถ้าจะรันบนเบราว์เซอร์

### 2) Clone และติดตั้ง package

```bash
git clone https://github.com/yaneekumsudsang/Pok-mon-Team-Builder-App-65114540147.git
```
```bash
cd Pok-mon-Team-Builder-App-65114540147
```
```bash
git checkout CRUDpocketbase
```
```bash
flutter pub get
```
```bash
dart run bin/seed.dart
```

### 3) รันแอป
# Android emulator / device จริง
```bash
flutter run -d android
```
# iOS simulator (macOS เท่านั้น)
```bash
flutter run -d ios
```
# Web (Chrome)
```bash
flutter run -d chrome
```

### 4) ทดสอบ CRUD
ในหน้าแอป:
- Read: รายการสินค้าจะถูกโหลดจาก product
- Create: ใช้ปุ่ม Create หรือแบบฟอร์มที่มีให้ กรอก name, price, imageUrl (แนะนำให้ไป coppy url จากรูปภาพที่มีอยู่โดยกด edit เพิ่ม coppy ก่อน)
- Update: กดปุ่มแก้ไขบนการ์ดสินค้า แก้ไข 3 ฟิลด์นี้
- Delete: กดปุ่มลบบนการ์ดสินค้า
