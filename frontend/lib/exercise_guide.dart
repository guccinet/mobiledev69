enum ExerciseMotion {
  squat,
  lunge,
  pushUp,
  plank,
  crunch,
  legRaise,
  bicycle,
  deadBug,
  inclinePushUp,
  diamondPushUp,
  bridge,
  mountainClimber,
  armCircle,
  dip,
  pike,
  plankUpDown,
  wallPushUp,
  calfRaise,
  wallSit,
  superman,
  snowAngel,
  birdDog,
  cobra,
  swimmer,
  stretch,
}

class ExerciseGuide {
  const ExerciseGuide({
    required this.motion,
    required this.steps,
    required this.tip,
  });

  final ExerciseMotion motion;
  final List<String> steps;
  final String tip;
}

const _guides = <String, ExerciseGuide>{
  'crunches': ExerciseGuide(
    motion: ExerciseMotion.crunch,
    steps: ['นอนหงาย ชันเข่า วางมือแตะขมับเบา ๆ', 'เกร็งหน้าท้อง ยกไหล่ขึ้น แล้วค่อย ๆ วางลง'],
    tip: 'อย่าดึงคอ และให้หลังส่วนล่างแนบพื้น',
  ),
  'bicycle-crunch': ExerciseGuide(
    motion: ExerciseMotion.bicycle,
    steps: ['นอนหงาย ยกขาขึ้นและงอเข่า', 'บิดลำตัวให้ศอกเข้าหาเข่าฝั่งตรงข้าม สลับข้าง'],
    tip: 'หมุนจากลำตัว ไม่ดึงศีรษะด้วยมือ',
  ),
  'leg-raises': ExerciseGuide(
    motion: ExerciseMotion.legRaise,
    steps: ['นอนหงาย เหยียดขาตรงและวางมือข้างลำตัว', 'ยกขาขึ้น แล้วลดลงช้า ๆ โดยไม่ปล่อยหลังแอ่น'],
    tip: 'ถ้าหลังแอ่น ให้งอเข่าหรือยกขาไม่สูงมาก',
  ),
  'plank': ExerciseGuide(
    motion: ExerciseMotion.plank,
    steps: ['วางท่อนแขนและปลายเท้าบนพื้น', 'เกร็งหน้าท้อง ค้างลำตัวเป็นเส้นตรง'],
    tip: 'อย่าปล่อยสะโพกตกหรือยกสูงเกินไป',
  ),
  'mountain-climbers': ExerciseGuide(
    motion: ExerciseMotion.mountainClimber,
    steps: ['เริ่มในท่าวิดพื้น แขนเหยียดตรง', 'ดึงเข่าเข้าหาหน้าอกสลับซ้ายขวาอย่างต่อเนื่อง'],
    tip: 'รักษาไหล่ให้อยู่เหนือข้อมือ และคุมลำตัวไม่ให้โยก',
  ),
  'dead-bug': ExerciseGuide(
    motion: ExerciseMotion.deadBug,
    steps: ['นอนหงาย ยกแขนและงอเข่าทำมุมประมาณ 90 องศา', 'เหยียดแขนกับขาฝั่งตรงข้าม แล้วสลับข้าง'],
    tip: 'กดหลังส่วนล่างแนบพื้นตลอดการเคลื่อนไหว',
  ),
  'push-ups': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    steps: ['วางมือกว้างกว่าไหล่เล็กน้อยในท่าแพลงก์', 'งอศอกลดอกเข้าใกล้พื้น แล้วดันกลับขึ้น'],
    tip: 'ให้ศีรษะ หลัง และสะโพกอยู่ในแนวเดียวกัน',
  ),
  'wide-push-ups': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    steps: ['วางมือกว้างกว่าไหล่ในท่าแพลงก์', 'ลดตัวลงอย่างคุมได้ แล้วดันพื้นกลับขึ้น'],
    tip: 'อย่ากางศอกออกด้านข้างจนสุดช่วง',
  ),
  'incline-push-ups': ExerciseGuide(
    motion: ExerciseMotion.inclinePushUp,
    steps: ['วางมือบนขอบโต๊ะหรือพื้นผิวที่มั่นคง', 'งอศอกลดอกเข้าหาพื้นผิว แล้วดันกลับ'],
    tip: 'ตรวจให้พื้นผิวมั่นคงก่อนเริ่ม และรักษาลำตัวตรง',
  ),
  'diamond-push-ups': ExerciseGuide(
    motion: ExerciseMotion.diamondPushUp,
    steps: ['วางมือชิดกันใต้หน้าอกในท่าแพลงก์', 'งอศอกลดตัวลง แล้วดันกลับขึ้น'],
    tip: 'เริ่มจากวางเข่าบนพื้นได้ หากยังควบคุมท่าไม่ไหว',
  ),
  'shoulder-taps': ExerciseGuide(
    motion: ExerciseMotion.plank,
    steps: ['เริ่มท่าแพลงก์แขนเหยียด มืออยู่ใต้หัวไหล่', 'ยกมือแตะไหล่ฝั่งตรงข้าม สลับข้าง'],
    tip: 'แยกเท้าให้กว้างขึ้นเพื่อช่วยทรงตัว และลดการบิดสะโพก',
  ),
  'knee-push-ups': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    steps: ['วางเข่าไว้บนพื้นและจัดลำตัวเป็นแนวตรง', 'งอศอกลดอกลง แล้วดันตัวกลับขึ้น'],
    tip: 'อย่าหย่อนสะโพกหรือแอ่นหลัง',
  ),
  'triceps-dips': ExerciseGuide(
    motion: ExerciseMotion.dip,
    steps: ['วางมือบนขอบเก้าอี้หรือพื้นผิวที่มั่นคง', 'งอศอกลดสะโพกลง แล้วดันตัวกลับขึ้น'],
    tip: 'ใช้เก้าอี้ที่ไม่เลื่อน และอย่าลดตัวลึกจนเจ็บไหล่',
  ),
  'pike-push-ups': ExerciseGuide(
    motion: ExerciseMotion.pike,
    steps: ['ยกสะโพกสูงเป็นรูปตัว V คว่ำ มือวางกว้างเท่าไหล่', 'งอศอกลดศีรษะลงระหว่างมือ แล้วดันขึ้น'],
    tip: 'เริ่มด้วยช่วงการเคลื่อนไหวสั้น ๆ หากไหล่ยังไม่แข็งแรง',
  ),
  'arm-circles': ExerciseGuide(
    motion: ExerciseMotion.armCircle,
    steps: ['ยืนตัวตรง กางแขนออกระดับหัวไหล่', 'หมุนแขนเป็นวงเล็ก ๆ ไปข้างหน้า แล้วสลับทิศ'],
    tip: 'ผ่อนคลายหัวไหล่ ไม่ยกไหล่เข้าใกล้หู',
  ),
  'plank-up-downs': ExerciseGuide(
    motion: ExerciseMotion.plankUpDown,
    steps: ['เริ่มในท่าแพลงก์แขนเหยียดตรง', 'ลดลงวางท่อนแขนทีละข้าง แล้วดันกลับขึ้นสลับข้าง'],
    tip: 'พยายามให้สะโพกนิ่งและสลับแขนที่เริ่มก่อน',
  ),
  'close-grip-push-ups': ExerciseGuide(
    motion: ExerciseMotion.pushUp,
    steps: ['วางมือแคบกว่าหัวไหล่ใต้หน้าอก', 'งอศอกชิดลำตัว ลดตัวลง แล้วดันกลับขึ้น'],
    tip: 'ปรับวางเข่าบนพื้นได้ และหยุดหากข้อมือเจ็บ',
  ),
  'wall-push-ups': ExerciseGuide(
    motion: ExerciseMotion.wallPushUp,
    steps: ['ยืนหันหน้าเข้ากำแพง วางมือระดับหน้าอก', 'งอศอกพาอกเข้าหากำแพง แล้วดันกลับออก'],
    tip: 'เกร็งลำตัวและให้ส้นเท้าแนบพื้น',
  ),
  'squats': ExerciseGuide(
    motion: ExerciseMotion.squat,
    steps: ['ยืนแยกเท้ากว้างประมาณหัวไหล่', 'ดันสะโพกไปด้านหลัง ย่อลง แล้วดันส้นเท้ากลับมายืน'],
    tip: 'ให้เข่าไปทิศทางเดียวกับปลายเท้า และไม่ยกส้น',
  ),
  'reverse-lunges': ExerciseGuide(
    motion: ExerciseMotion.lunge,
    steps: ['ยืนตรง ก้าวขาข้างหนึ่งไปด้านหลัง', 'ย่อเข่าทั้งสองข้าง แล้วดันกลับมายืน สลับข้าง'],
    tip: 'ก้าวให้มั่นคงและรักษาลำตัวตั้งตรง',
  ),
  'glute-bridges': ExerciseGuide(
    motion: ExerciseMotion.bridge,
    steps: ['นอนหงาย ชันเข่าและวางเท้าราบกับพื้น', 'เกร็งก้น ยกสะโพกขึ้น แล้วลดลงช้า ๆ'],
    tip: 'อย่าแอ่นหลังส่วนล่างเมื่อยกสะโพก',
  ),
  'calf-raises': ExerciseGuide(
    motion: ExerciseMotion.calfRaise,
    steps: ['ยืนตัวตรง จับพนักเก้าอี้เพื่อทรงตัวได้', 'เขย่งปลายเท้าขึ้น ค้างสั้น ๆ แล้วลดส้นลง'],
    tip: 'เคลื่อนไหวช้า ๆ และไม่โยกตัวช่วย',
  ),
  'wall-sit': ExerciseGuide(
    motion: ExerciseMotion.wallSit,
    steps: ['ยืนพิงกำแพงแล้วก้าวเท้าออกมาด้านหน้า', 'ไถลตัวลงจนเข่างอในระดับที่สบาย แล้วค้างไว้'],
    tip: 'ให้เข่าอยู่เหนือข้อเท้า และไม่ฝืนหากมีอาการเจ็บ',
  ),
  'sumo-squats': ExerciseGuide(
    motion: ExerciseMotion.squat,
    steps: ['ยืนแยกเท้ากว้างและหันปลายเท้าออกเล็กน้อย', 'ย่อสะโพกลงระหว่างขา แล้วดันกลับขึ้น'],
    tip: 'รักษาหลังให้เป็นกลางและให้เข่าตามแนวปลายเท้า',
  ),
  'superman': ExerciseGuide(
    motion: ExerciseMotion.superman,
    steps: ['นอนคว่ำ เหยียดแขนไปด้านหน้า', 'ยกแขนและขาขึ้นเล็กน้อย ค้าง แล้วลดลง'],
    tip: 'ยกเพียงเท่าที่สบาย ไม่แหงนคอหรือบีบหลังมากเกินไป',
  ),
  'reverse-snow-angels': ExerciseGuide(
    motion: ExerciseMotion.snowAngel,
    steps: ['นอนคว่ำ เหยียดแขนข้างลำตัว', 'ยกแขนเล็กน้อยแล้วกวาดเป็นวงเหนือศีรษะ'],
    tip: 'รักษาหน้าผากใกล้พื้นและขยับแขนอย่างนุ่มนวล',
  ),
  'bird-dog': ExerciseGuide(
    motion: ExerciseMotion.birdDog,
    steps: ['ตั้งตัวบนมือและเข่า มืออยู่ใต้ไหล่', 'เหยียดแขนข้างหนึ่งกับขาฝั่งตรงข้าม แล้วสลับ'],
    tip: 'อย่าบิดสะโพกหรือแอ่นหลัง',
  ),
  'cobra-stretch': ExerciseGuide(
    motion: ExerciseMotion.cobra,
    steps: ['นอนคว่ำ วางมือข้างลำตัวใต้หัวไหล่', 'ค่อย ๆ ยกลำตัวส่วนบนขึ้นเท่าที่สบาย'],
    tip: 'ใช้แรงแขนเพียงเล็กน้อย และหยุดหากหลังรู้สึกเจ็บ',
  ),
  'swimmers': ExerciseGuide(
    motion: ExerciseMotion.swimmer,
    steps: ['นอนคว่ำ เหยียดแขนและขาออกจากลำตัว', 'ยกแขนกับขาสลับกันเล็กน้อยอย่างต่อเนื่อง'],
    tip: 'มองพื้นและรักษาคอให้อยู่แนวเดียวกับหลัง',
  ),
  'pike-hold': ExerciseGuide(
    motion: ExerciseMotion.pike,
    steps: ['วางมือบนพื้นและยกสะโพกสูงเป็นรูปตัว V คว่ำ', 'กดมือกับพื้นและค้างในท่าที่หายใจสะดวก'],
    tip: 'งอเข่าเล็กน้อยได้ และไม่ฝืนเอ็นหลังขา',
  ),
  'recovery-stretch': ExerciseGuide(
    motion: ExerciseMotion.stretch,
    steps: ['เริ่มยืนในท่าที่มั่นคงและผ่อนคลาย', 'ยืดแขนขึ้นเหนือศีรษะ หายใจช้า ๆ แล้วคลายท่า'],
    tip: 'ยืดเพียงจนรู้สึกตึงเล็กน้อย ไม่เด้งตัวหรือฝืนจนเจ็บ',
  ),
};

ExerciseGuide guideForExercise(String id) =>
    _guides[id] ??
    const ExerciseGuide(
      motion: ExerciseMotion.stretch,
      steps: ['เริ่มในท่าที่มั่นคง', 'เคลื่อนไหวช้า ๆ ตามจังหวะหายใจ'],
      tip: 'หยุดทันทีหากรู้สึกเจ็บหรือเวียนศีรษะ',
    );
