# Pokémon Team Builder


### ฟีเจอร์ที่เพิ่มมา (Enhancements)

* 🖼️ **แสดงภาพโปเกมอน** จาก PokeAPI คู่กับชื่อ
* ✏️ **แก้ไขชื่อทีม** และบันทึกด้วย **GetStorage**
* 🎨 **แอนิเมชัน/เอฟเฟกต์ตอบสนอง** เมื่อเลือก/ยกเลิกการเลือกโปเกมอน
* 📦 **บันทึกทีมทั้งหมด** (ชื่อ + ภาพ) และโหลดกลับมาอัตโนมัติเมื่อเปิดแอปใหม่
* 🔗 ปุ่ม **Reset Team** เพื่อล้างข้อมูลที่เลือกและที่บันทึก
* 💡 (เสริม) **Search bar** ค้นหาชื่อโปเกมอนในลิสต์

* **Flutter** 3.16+ (ทดสอบบน 3.22.x)
* **Dart** 3+
* **GetX** สำหรับ state management & routing
* **GetStorage** สำหรับ local storage
* **http** สำหรับเรียก REST API (PokeAPI)
* (เสริม) **flutter\_animate** หรือ widget ของ Flutter (`AnimatedContainer`, `ScaleTransition`)

## ▶️ วิธีรันโปรเจกต์

### 1) เตรียมเครื่อง

* ติดตั้ง **Flutter SDK** และตรวจสอบด้วย `flutter doctor`
* ติดตั้ง Android Studio/Xcode ถ้าจะรันบนมือถือ หรือเปิด web support (`flutter config --enable-web`) ถ้าจะรันบนเบราว์เซอร์

### 2) Clone และติดตั้ง package

```bash
git clone Pok-mon-Team-Builder-App-65114540147
cd Pok-mon-Team-Builder-App-65114540147
flutter pub get
```

### 3) รันแอป

```bash
# Android emulator / device จริง
flutter run -d android

# iOS simulator (macOS เท่านั้น)
flutter run -d ios

# Web (Chrome)
flutter run -d chrome
```

### 4) Build release

```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
```

---

## 🧭 วิธีใช้งาน

1. เปิดแอป → รายชื่อโปเกมอนโหลดขึ้นมา
2. ใช้ search bar เพื่อค้นหา
3. แตะการ์ด → เลือกโปเกมอน (สูงสุด 3 ตัว)
4. ไปที่ Team Manager → ตั้งชื่อทีม และกดบันทึก
5. ปิดและเปิดใหม่ → ทีมที่บันทึกยังอยู่
6. กด **Reset Team** → ล้างข้อมูลทั้งหมด

---

## 🧪 เช็กลิสต์ทดสอบ

* [*] ลิสต์โหลดครบ และแสดงสถานะกำลังโหลด
* [*] เลือก/ยกเลิก แสดงผลทันที (Obx)
* [*] เลือกเกิน 3 ตัวไม่ได้
* [*] ชื่อทีมบันทึกและโหลดกลับมาได้
* [*] Reset ล้างข้อมูลได้จริง
* [*] Search กรองชื่อได้แบบ real-time
