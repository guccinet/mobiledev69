# แอปออกกำลังกายที่บ้าน

แอป Flutter สำหรับออกกำลังกายโดยไม่ใช้อุปกรณ์ เชื่อมต่อกับ Django REST API
เพื่อสมัครสมาชิก เข้าสู่ระบบ เลือกแผนฝึก 4 สัปดาห์ และบันทึกประวัติการฝึก

## ฟีเจอร์

- สมัครสมาชิก เข้าสู่ระบบ และออกจากระบบด้วยอีเมลและรหัสผ่าน
- เลือกพื้นที่ฝึก: หน้าท้อง, หน้าอก, แขน, ขา หรือไหล่และหลัง
- เลือกระดับ: เริ่มฝึก, ปานกลาง หรือขั้นสูง
- ดูแผนฝึก 28 วัน พร้อมรายการท่า จำนวนเซต และจำนวนครั้งหรือเวลา
- ดูภาพเคลื่อนไหวสาธิตท่าฝึก พร้อมมุมกล้องที่เหมาะกับท่า ลูกศรบอกทิศทาง
  คำแนะนำทีละขั้น และข้อควรระวัง
- ฝึกทีละท่า โดยกดยืนยันเพื่อไปท่าถัดไปเมื่อทำจำนวนครั้งและเซตครบ
- ท่าที่กำหนดเป็นเวลา เช่น Plank มีตัวนับถอยหลังและไปต่อได้เมื่อครบเวลา
- เพิ่มวันพักฟื้นบนปฏิทินหลังบันทึกการฝึกสำเร็จติดต่อกัน 3 วัน โดยไม่คิดเป็นวันฝึก
- จับเวลา session และหยุด/เริ่มเวลาได้ระหว่างฝึก
- วันที่ฝึกสำเร็จแล้วเปิดดูท่าซ้ำได้โดยไม่เริ่มตัวจับเวลาหรือนับถอยหลัง
- เปิดดูสถิติบนหน้าแดชบอร์ด และดูประวัติการฝึกในหน้าแยก
- จัดการข้อมูลโปรไฟล์ส่วนตัว ได้แก่ เพศ อายุ น้ำหนัก และส่วนสูง โดยบันทึกกับบัญชีผู้ใช้
- แสดงเงารูปร่างคนสีขาวโดยประมาณบนการ์ดสถิติ ปรับตามส่วนสูงและน้ำหนักในโปรไฟล์
- ดูกราฟความก้าวหน้ารายสัปดาห์ 8 สัปดาห์ โดยเลือกจำนวนวันฝึก นาที หรือแคลอรี
- รับคำแนะนำระดับเริ่มต้นจากอายุและประวัติการฝึก โดยเพศและน้ำหนักไม่ถูกใช้ตัดสินระดับโดยตรง

คำแนะนำระดับเป็นแนวทางเบื้องต้น: หากอายุต่ำกว่า 18 ปีหรือ 60 ปีขึ้นไป
หรือข้อมูลอายุยังไม่ครบ จะแนะนำระดับเริ่มฝึกไว้ก่อน สำหรับช่วงอายุ 18–59 ปี
จะแนะนำระดับปานกลางเมื่อมีประวัติฝึกสำเร็จอย่างน้อย 8 ครั้งใน 28 วันล่าสุด
ระบบไม่แนะนำระดับขั้นสูงอัตโนมัติ และไม่ใช้เพศหรือน้ำหนักเป็นตัวตัดสิน
คำแนะนำนี้ไม่ใช่การประเมินทางการแพทย์

วันพักฟื้นจะแสดงในวันถัดไปหลังบันทึกวันฝึกสำเร็จติดต่อกันครบ 3 วัน
วันพักประจำทุกวันที่ 7 ของแผนยังคงมีอยู่ และวันพักจะไม่ถูกบันทึกเป็นการฝึก
หากมีวันที่ไม่ได้ฝึก การนับวันฝึกติดต่อกันจะเริ่มใหม่

> จำนวนแคลอรีเป็นค่าประมาณจากเวลาที่บันทึก โดยคิด 5 kcal ต่อนาที
> ไม่ใช่การวัดพลังงานที่เผาผลาญจริง

## เครื่องมือที่ต้องใช้

- Python 3.9–3.12
- Flutter และ Dart ตามเวอร์ชันที่กำหนดใน `pubspec.yaml`

## เริ่มใช้งาน

### 1. ติดตั้งและเริ่ม Django API

จากโฟลเดอร์หลักของโปรเจ็กต์ สร้าง virtual environment และติดตั้ง dependencies:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```

สร้างตารางฐานข้อมูลและเริ่มเซิร์ฟเวอร์:

```powershell
.\.venv\Scripts\python.exe backend\manage.py migrate
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:3000
```

API สำหรับการพัฒนาในเครื่องจะอยู่ที่ `http://localhost:3000/api`
และข้อมูลจะเก็บใน SQLite ที่ `backend/db.sqlite3`

### 2. เริ่มแอป Flutter

เปิด terminal อีกหน้าต่างที่โฟลเดอร์หลักของโปรเจ็กต์:

```powershell
flutter pub get
flutter run -d chrome
```

แอปใช้ API URL เริ่มต้นดังนี้:

- Flutter Web: `http://localhost:3000/api`
- Android Emulator: `http://10.0.2.2:3000/api`

หากรันบนโทรศัพท์จริง ให้ใช้ IP ของคอมพิวเตอร์ที่อยู่ในเครือข่ายเดียวกัน
และส่ง URL ให้ Flutter:

```powershell
$env:DJANGO_ALLOWED_HOSTS = "localhost,127.0.0.1,10.0.2.2,YOUR_COMPUTER_IP"
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:3000
```

เปิดแอป Flutter โดยกำหนด URL เดียวกัน:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3000/api
```

เปลี่ยน `YOUR_COMPUTER_IP` เป็น IP จริงของคอมพิวเตอร์ เช่น `192.168.1.20`
และตรวจสอบว่า firewall อนุญาตการเชื่อมต่อพอร์ต `3000`

## API

ทุก endpoint ที่ระบุด้านล่างอยู่ใต้ `/api` เช่น
`GET http://localhost:3000/api/plan?focus=abs&difficulty=beginner`

| Method | Endpoint | การทำงาน |
| --- | --- | --- |
| `GET` | `/health` | ตรวจสอบสถานะ API |
| `POST` | `/auth/register` | สมัครสมาชิกและรับ token |
| `POST` | `/auth/login` | เข้าสู่ระบบและรับ token |
| `POST` | `/auth/logout` | เพิกถอน token ปัจจุบัน |
| `GET` | `/profile` | ดูข้อมูลโปรไฟล์ของผู้ใช้ |
| `PATCH` | `/profile` | แก้ไขเพศ อายุ น้ำหนัก และส่วนสูง |
| `GET` | `/plan` | ดูแผนฝึก 28 วัน |
| `GET` | `/exercises` | ดูรายการท่าฝึก |
| `GET` | `/workouts` | ดูประวัติการฝึกของผู้ใช้ |
| `POST` | `/workouts` | บันทึกวันที่ฝึกเสร็จ |
| `GET` | `/stats` | ดูสถิติการฝึกสะสม |

การสมัครสมาชิกและเข้าสู่ระบบใช้ JSON รูปแบบนี้:

```json
{
  "email": "you@example.com",
  "password": "your-password"
}
```

การดูแผนและรายการท่าระบุพื้นที่ฝึกและระดับได้ด้วย query parameters:

```text
/plan?focus=abs&difficulty=beginner
/exercises?focus=chest&difficulty=intermediate
```

ค่าพื้นที่ฝึกที่รองรับ: `abs`, `chest`, `arms`, `legs`, `shoulder_back`

ค่าระดับที่รองรับ: `beginner`, `intermediate`, `advanced`

หน้าโปรไฟล์รองรับข้อมูลเพศ อายุ น้ำหนัก (กก.) และส่วนสูง (ซม.)
ส่ง token ใน header `Authorization: Token <token>` เพื่ออ่านหรือแก้ไขข้อมูล:

```http
GET /api/profile
PATCH /api/profile
Content-Type: application/json
```

ตัวอย่างข้อมูลสำหรับ `PATCH`:

```json
{
  "gender": "female",
  "age": 28,
  "weightKg": 62.5,
  "heightCm": 168.0
}
```

ค่า `gender` ที่รองรับ: `male`, `female`, `other`, `prefer_not_to_say`
แต่ละช่องสามารถเว้นว่างหรือส่ง `null` ได้

การบันทึกการฝึกต้องส่ง token ใน header
`Authorization: Token <token>` และส่งข้อมูล JSON:

```json
{
  "focus": "abs",
  "difficulty": "beginner",
  "dayNumber": 1,
  "durationMinutes": 12
}
```

แต่ละวันฝึกในแผนบันทึกได้ครั้งเดียว และ API จะปฏิเสธวันที่ยังมาไม่ถึง
หรือวันที่กำหนดเป็นวันพักฟื้น
ประวัติและสถิติจะมองเห็นได้เฉพาะผู้ใช้ที่เข้าสู่ระบบบัญชีนั้น

## การทดสอบ

รันทดสอบ Django API:

```powershell
.\.venv\Scripts\python.exe backend\manage.py test workouts
```

ตรวจการตั้งค่าและ migration:

```powershell
.\.venv\Scripts\python.exe backend\manage.py check
.\.venv\Scripts\python.exe backend\manage.py makemigrations --check --dry-run
```

รันทดสอบ Flutter และตรวจวิเคราะห์โค้ด:

```powershell
flutter test
flutter analyze
```

## การตั้งค่าก่อนใช้งานจริง

การตั้งค่าเริ่มต้นของ Django มีไว้สำหรับการพัฒนาในเครื่องเท่านั้น
ก่อนนำขึ้นใช้งานจริง ให้กำหนด `DJANGO_DEBUG=0`, ตั้งค่า
`DJANGO_SECRET_KEY` ที่เป็นความลับ, จำกัด `DJANGO_ALLOWED_HOSTS`,
จำกัด CORS ให้เฉพาะ origin ที่อนุญาต และใช้ HTTPS
