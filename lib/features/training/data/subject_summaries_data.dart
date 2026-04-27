class SubjectSummary {
  final String title;
  final List<SummarySection> sections;
  final List<String> worksheetIds;

  const SubjectSummary({
    required this.title,
    required this.sections,
    this.worksheetIds = const [],
  });
}

class SummarySection {
  final String title;
  final List<SummaryItem> items;

  const SummarySection({required this.title, required this.items});
}

abstract class SummaryItem {
  const SummaryItem();
}

class SummaryFormula extends SummaryItem {
  final List<String> lines;
  const SummaryFormula(this.lines);
}

class SummaryUsage extends SummaryItem {
  final List<String> lines;
  const SummaryUsage(this.lines);
}

class SummaryExample extends SummaryItem {
  final List<String> lines;
  const SummaryExample(this.lines);
}

class SummaryTip extends SummaryItem {
  final List<String> lines;
  const SummaryTip(this.lines);
}

class SummaryText extends SummaryItem {
  final String text;
  const SummaryText(this.text);
}

class SummaryList extends SummaryItem {
  final List<String> items;
  const SummaryList(this.items);
}

// Data store
final Map<String, SubjectSummary> subjectSummaries = {
  // 1) Present Simple vs Present Continuous
  'A1-PS-PC-01': const SubjectSummary(
    title: 'Present Simple vs Present Continuous',
    worksheetIds: ['A1-PS-PC-01', 'A1-PS-PC-02'],
    sections: [
      SummarySection(
        title: 'Present Simple (rutin / genel gerçek)',
        items: [
          SummaryFormula([
            '(+) S + V1(s/es)',
            '(-) S + don’t/doesn’t + V1',
            '(?) Do/Does + S + V1?',
          ]),
          SummaryUsage([
            'Rutinler: always, usually, often, sometimes',
            'Genel gerçekler: Water boils at 100°C.',
          ]),
          SummaryExample([
            'I work every day.\n(Her gün çalışırım.)',
            'She doesn’t like coffee.\n(O kahve sevmez.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Present Continuous (şu an / geçici)',
        items: [
          SummaryFormula([
            '(+) S + am/is/are + V-ing',
            '(-) S + am/is/are + not + V-ing',
            '(?) Am/Is/Are + S + V-ing?',
          ]),
          SummaryUsage([
            'Şu an olan: now, right now, at the moment',
            'Geçici durum: I’m staying with my friend this week.',
          ]),
          SummaryExample([
            'I am studying now.\n(Şu an ders çalışıyorum.)',
            'Are you watching TV?\n(Televizyon mu izliyorsun?)',
          ]),
          SummaryTip([
            '“Every day” → genelde Simple',
            '“Right now” → genelde Continuous',
          ]),
        ],
      ),
    ],
  ),

  'A1-PS-PC-02': const SubjectSummary(
    title: 'Present Simple vs Present Continuous',
    worksheetIds: ['A1-PS-PC-01', 'A1-PS-PC-02'],
    sections: [
      SummarySection(
        title: 'Present Simple (rutin / genel gerçek)',
        items: [
          SummaryFormula([
            '(+) S + V1(s/es)',
            '(-) S + don’t/doesn’t + V1',
            '(?) Do/Does + S + V1?',
          ]),
          SummaryUsage([
            'Rutinler: always, usually, often, sometimes',
            'Genel gerçekler: Water boils at 100°C.',
          ]),
          SummaryExample([
            'I work every day.\n(Her gün çalışırım.)',
            'She doesn’t like coffee.\n(O kahve sevmez.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Present Continuous (şu an / geçici)',
        items: [
          SummaryFormula([
            '(+) S + am/is/are + V-ing',
            '(-) S + am/is/are + not + V-ing',
            '(?) Am/Is/Are + S + V-ing?',
          ]),
          SummaryUsage([
            'Şu an olan: now, right now, at the moment',
            'Geçici durum: I’m staying with my friend this week.',
          ]),
          SummaryExample([
            'I am studying now.\n(Şu an ders çalışıyorum.)',
            'Are you watching TV?\n(Televizyon mu izliyorsun?)',
          ]),
          SummaryTip([
            '“Every day” → genelde Simple',
            '“Right now” → genelde Continuous',
          ]),
        ],
      ),
    ],
  ),

  // 2) Questions (5W1H + Do/Does + Word Order)
  'A1-QUEST-01': const SubjectSummary(
    title: 'Questions (5W1H + Do/Does)',
    sections: [
      SummarySection(
        title: '5W1H (Wh- Questions)',
        items: [
          SummaryList([
            'What (ne) • Where (nerede) • When (ne zaman)',
            'Who (kim) • Why (neden) • How (nasıl)',
          ]),
          SummaryText('Word order (genel):'),
          SummaryFormula([
            'Wh + auxiliary + subject + verb + … ?',
            'Auxiliary: do/does (present simple)',
          ]),
          SummaryExample([
            'Where do you live?\n(Nerede yaşıyorsun?)',
            'Why does he study English?\n(O neden İngilizce çalışıyor?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Do / Does Questions (Present Simple)',
        items: [
          SummaryFormula([
            '(?) Do/Does + S + V1?',
            'Short answer: Yes, I do. / No, she doesn’t.',
          ]),
          SummaryExample([
            'Do you like tea?\n(Çay sever misin?)',
            'Does she work here?\n(O burada mı çalışıyor?)',
          ]),
          SummaryTip(['Does gelince fiil V1 kalır: ✅ Does he play? (❌ plays)']),
        ],
      ),
    ],
  ),

  // 3) There is / There are + some / any
  'A1-THERE-01': const SubjectSummary(
    title: 'There is / There are + some / any',
    sections: [
      SummarySection(
        title: 'There is / There are (var / yok)',
        items: [
          SummaryFormula([
            '(+) There is (tekil) / There are (çoğul)',
            '(-) There isn’t / There aren’t',
            '(?) Is there … ? / Are there … ?',
          ]),
          SummaryExample([
            'There is a cat.\n(Bir kedi var.)',
            'There are two chairs.\n(İki sandalye var.)',
            'Is there a bank near here?\n(Buraya yakın bir banka var mı?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Some / Any',
        items: [
          SummaryText('Kural (kolay):'),
          SummaryList(['(+) Cümle → genelde some', '(-) ve (?) → genelde any']),
          SummaryExample([
            'There is some milk.\n(Biraz süt var.)',
            'There aren’t any apples.\n(Hiç elma yok.)',
            'Is there any water?\n(Hiç su var mı?)',
          ]),
          SummaryTip(['İstisna (teklif/istek): Would you like some tea? ✅']),
        ],
      ),
    ],
  ),

  // 4) Countable vs Uncountable (Basic)
  'A1-CU-01': const SubjectSummary(
    title: 'Countable vs Uncountable',
    worksheetIds: ['A1-CU-01', 'A1-CU-02'],
    sections: [
      SummarySection(
        title: 'Countable (sayılabilen)',
        items: [
          SummaryText('Örnek: apple, book, chair'),
          SummaryList([
            'a/an + singular: an apple',
            'many + plural: many books',
          ]),
        ],
      ),
      SummarySection(
        title: 'Uncountable (sayılamayan)',
        items: [
          SummaryText('Örnek: water, rice, bread, money'),
          SummaryList(['some + noun: some water', 'much + noun: much money']),
        ],
      ),
      SummarySection(
        title: 'much / many hızlı kural',
        items: [
          SummaryList([
            'many + plural countable → many cars',
            'much + uncountable → much sugar',
          ]),
          SummaryExample([
            'How many students are there?\n(Kaç öğrenci var?)',
            'How much time do we have?\n(Ne kadar vaktimiz var?)',
          ]),
          SummaryTip([
            'Uncountable için “1 water” ❌',
            'Onun yerine: a bottle of water ✅',
          ]),
        ],
      ),
    ],
  ),

  'A1-CU-02': const SubjectSummary(
    title: 'Countable vs Uncountable',
    worksheetIds: ['A1-CU-01', 'A1-CU-02'],
    sections: [
      SummarySection(
        title: 'Countable (sayılabilen)',
        items: [
          SummaryText('Örnek: apple, book, chair'),
          SummaryList([
            'a/an + singular: an apple',
            'many + plural: many books',
          ]),
        ],
      ),
      SummarySection(
        title: 'Uncountable (sayılamayan)',
        items: [
          SummaryText('Örnek: water, rice, bread, money'),
          SummaryList(['some + noun: some water', 'much + noun: much money']),
        ],
      ),
      SummarySection(
        title: 'much / many hızlı kural',
        items: [
          SummaryList([
            'many + plural countable → many cars',
            'much + uncountable → much sugar',
          ]),
          SummaryExample([
            'How many students are there?\n(Kaç öğrenci var?)',
            'How much time do we have?\n(Ne kadar vaktimiz var?)',
          ]),
          SummaryTip([
            'Uncountable için “1 water” ❌',
            'Onun yerine: a bottle of water ✅',
          ]),
        ],
      ),
    ],
  ),

  // --- A2 ---

  // 1) Present Perfect vs Past Simple
  'A2-PP-PS-01': const SubjectSummary(
    title: 'Present Perfect vs Past Simple',
    sections: [
      SummarySection(
        title: 'Present Perfect (deneyim / sonuç / zaman belli değil)',
        items: [
          SummaryFormula([
            '(+) S + have/has + V3',
            '(-) S + haven’t/hasn’t + V3',
            '(?) Have/Has + S + V3?',
          ]),
          SummaryText('İpuçları: just / already / yet / ever / never'),
          SummaryExample([
            'I have finished my homework.\n(Ödevimi bitirdim.)',
            'Have you ever been to Italy?\n(Hiç İtalya’da bulundun mu?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Past Simple (geçmişte bitti, zamanı belli)',
        items: [
          SummaryFormula([
            '(+) S + V2',
            '(-) S + didn’t + V1',
            '(?) Did + S + V1?',
          ]),
          SummaryText('İpuçları: yesterday / last week / in 2020 / ago'),
          SummaryExample([
            'I met him yesterday.\n(Onunla dün tanıştım.)',
            'Did you see the film last night?\n(Filmi dün gece gördün mü?)',
          ]),
          SummaryTip(['ago / yesterday / last… → Past Simple ✅']),
        ],
      ),
    ],
  ),

  // 2) Past Simple vs Past Continuous (when/while)
  'A2-PS-PC-01': const SubjectSummary(
    title: 'Past Simple vs Past Continuous',
    sections: [
      SummarySection(
        title: 'Past Continuous (arka plan / uzun olay)',
        items: [
          SummaryFormula(['S + was/were + V-ing']),
        ],
      ),
      SummarySection(
        title: 'Past Simple (kısa olay / kesen olay)',
        items: [
          SummaryFormula(['S + V2']),
        ],
      ),
      SummarySection(
        title: 'when / while kullanımı',
        items: [
          SummaryFormula([
            'was/were + V-ing when V2',
            'while was/were + V-ing, V2',
          ]),
          SummaryExample([
            'I was watching TV when he arrived.\n(O geldiğinde televizyon izliyordum.)',
            'While she was cooking, the phone rang.\n(O yemek yaparken telefon çaldı.)',
          ]),
          SummaryTip(['“uzun” → Continuous, “kesti/bitti” → Simple']),
        ],
      ),
    ],
  ),

  // 3) Will vs Be going to
  'A2-FUTURE-01': const SubjectSummary(
    title: 'Will vs Be going to',
    sections: [
      SummarySection(
        title: 'WILL (ani karar / tahmin / teklif)',
        items: [
          SummaryFormula([
            '(+) S + will + V1',
            '(-) S + won’t + V1',
            '(?) Will + S + V1?',
          ]),
          SummaryText('İpuçları: I think… / probably / I’ll… / OK!'),
          SummaryExample([
            'I’m thirsty. I will get some water.\n(Susadım. Biraz su alacağım.)',
            'I think it will rain.\n(Sanırım yağmur yağacak.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'BE GOING TO (plan / güçlü işaret)',
        items: [
          SummaryFormula(['S + am/is/are + going to + V1']),
          SummaryText('İpuçları: plan + “kanıt var”'),
          SummaryExample([
            'I am going to study tonight.\n(Bu gece ders çalışacağım.)',
            'Look at those clouds! It is going to rain.\n(Şu bulutlara bak! Yağmur yağacak.)',
          ]),
          SummaryTip(['Plan = going to • Anlık karar = will']),
        ],
      ),
    ],
  ),

  // 4) Present Continuous (future) vs Going to
  'A2-FUTURE-02': const SubjectSummary(
    title: 'Present Continuous (future) vs Going to',
    sections: [
      SummarySection(
        title: 'Present Continuous (future) → kesin ayarlanmış plan',
        items: [
          SummaryFormula(['S + am/is/are + V-ing (future meaning)']),
          SummaryText('İpuçları: genelde time/place belli'),
          SummaryExample([
            'I’m meeting my friend at 7.\n(Saat 7’de arkadaşımla buluşuyorum.)',
            'We’re flying to Ankara tomorrow.\n(Yarın Ankara’ya uçuyoruz.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Going to → niyet/plan (detay net olmasa da olur)',
        items: [
          SummaryFormula(['S + am/is/are + going to + V1']),
          SummaryExample([
            'I’m going to buy a new phone.\n(Yeni bir telefon alacağım.)',
          ]),
          SummaryTip([
            '“Saat gün belli randevu” → Present Continuous ✅',
            '“Niyet/plan” → Going to ✅',
          ]),
        ],
      ),
    ],
  ),

  // 5) Comparatives & Superlatives (A2-COMP-SUP-01 varsayıldı)
  'A2-COMP-01': const SubjectSummary(
    title: 'Comparatives & Superlatives',
    worksheetIds: ['A2-COMP-01', 'A2-COMP-02'],
    sections: [
      SummarySection(
        title: 'Comparative (karşılaştırma)',
        items: [
          SummaryFormula([
            'short adj: adj + -er + than → taller than',
            'long adj: more + adj + than → more interesting than',
            'irregular: good → better, bad → worse, far → farther/further',
          ]),
          SummaryExample([
            'This car is faster than that one.\n(Bu araba diğerinden daha hızlı.)',
            'This movie is more interesting than the other.\n(Bu film diğerinden daha ilginç.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Superlative (en …)',
        items: [
          SummaryFormula([
            'short adj: the + adj + -est → the tallest',
            'long adj: the most + adj → the most expensive',
            'irregular: best / worst',
          ]),
          SummaryExample([
            'She is the smartest student.\n(O en zeki öğrenci.)',
            'It’s the most beautiful place.\n(Burası en güzel yer.)',
          ]),
        ],
      ),
    ],
  ),

  'A2-COMP-02': const SubjectSummary(
    title: 'Comparatives & Superlatives',
    worksheetIds: ['A2-COMP-01', 'A2-COMP-02'],
    sections: [
      SummarySection(
        title: 'Comparative (karşılaştırma)',
        items: [
          SummaryFormula([
            'short adj: adj + -er + than → taller than',
            'long adj: more + adj + than → more interesting than',
            'irregular: good → better, bad → worse, far → farther/further',
          ]),
          SummaryExample([
            'This car is faster than that one.\n(Bu araba diğerinden daha hızlı.)',
            'This movie is more interesting than the other.\n(Bu film diğerinden daha ilginç.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Superlative (en …)',
        items: [
          SummaryFormula([
            'short adj: the + adj + -est → the tallest',
            'long adj: the most + adj → the most expensive',
            'irregular: best / worst',
          ]),
          SummaryExample([
            'She is the smartest student.\n(O en zeki öğrenci.)',
            'It’s the most beautiful place.\n(Burası en güzel yer.)',
          ]),
        ],
      ),
    ],
  ),

  // 6) Relative Clauses (who / which / where)
  'A2-REL-01': const SubjectSummary(
    title: 'Relative Clauses (who / which / where)',
    sections: [
      SummarySection(
        title: 'Kısa kural',
        items: [
          SummaryList([
            'who → people (ki o kişi)',
            'which → things/animals (ki o şey)',
            'where → places (ki orası)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula(['noun + who/which/where + clause']),
          SummaryExample([
            'A doctor is a person who helps people.\n(Doktor, insanlara yardım eden bir kişidir.)',
            'A laptop is a thing which you use for work.\n(Dizüstü bilgisayar, iş için kullandığın bir eşyadır.)',
            'A café is a place where we meet.\n(Kafe, buluştuğumuz bir yerdir.)',
          ]),
          SummaryTip(['person=who • thing=which • place=where']),
        ],
      ),
    ],
  ),

  // --- B1 ---

  // 1) Passive Voice (Present/Past Simple Passive)
  'B1-PASSIVE-01': const SubjectSummary(
    title: 'Passive Voice (Present/Past Simple)',
    worksheetIds: ['B1-PASSIVE-01', 'B1-PASSIVE-02'],
    sections: [
      SummarySection(
        title: 'Ne zaman?',
        items: [
          SummaryList([
            'Yapan kişi önemli değil / bilinmiyor',
            'İş/sonuç önemli',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula([
            'Present Simple Passive: am/is/are + V3',
            'Past Simple Passive: was/were + V3',
            '(İstersen) by + agent: by Tom, by the police…',
          ]),
          SummaryExample([
            'Present: The car is washed every week.\n(Araba her hafta yıkanır.)',
            'Past: The window was broken last night.\n(Pencere dün gece kırıldı.)',
            'Agent: The book was written by Orwell.\n(Kitap Orwell tarafından yazıldı.)',
          ]),
          SummaryTip(['Active → Passive: Object başa geçer.']),
        ],
      ),
    ],
  ),

  'B1-PASSIVE-02': const SubjectSummary(
    title: 'Passive Voice (Present/Past Simple)',
    worksheetIds: ['B1-PASSIVE-01', 'B1-PASSIVE-02'],
    sections: [
      SummarySection(
        title: 'Ne zaman?',
        items: [
          SummaryList([
            'Yapan kişi önemli değil / bilinmiyor',
            'İş/sonuç önemli',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula([
            'Present Simple Passive: am/is/are + V3',
            'Past Simple Passive: was/were + V3',
            '(İstersen) by + agent: by Tom, by the police…',
          ]),
          SummaryExample([
            'Present: The car is washed every week.\n(Araba her hafta yıkanır.)',
            'Past: The window was broken last night.\n(Pencere dün gece kırıldı.)',
            'Agent: The book was written by Orwell.\n(Kitap Orwell tarafından yazıldı.)',
          ]),
          SummaryTip(['Active → Passive: Object başa geçer.']),
        ],
      ),
    ],
  ),

  // 2) Modals: should / must / have to / don’t have to
  'B1-MODALS-01': const SubjectSummary(
    title: 'Modals: should / must / have to',
    worksheetIds: ['B1-MODALS-01', 'B1-MODALS-02'],
    sections: [
      SummarySection(
        title: 'Anlamlar',
        items: [
          SummaryList([
            'should → tavsiye',
            'must → güçlü zorunluluk (konuşanın “çok gerekli” hissi)',
            'have to → kural/dış zorunluluk (iş, okul, yasa)',
            'don’t have to → zorunlu değil (serbest)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula([
            'modal + V1',
            'Negative: shouldn’t / mustn’t / don’t have to',
          ]),
          SummaryText('mustn’t = yasak'),
          SummaryText('don’t have to = gerek yok'),
          SummaryExample([
            'You should study more.\n(Daha fazla ders çalışmalısın.)',
            'You have to wear a helmet.\n(Kask takmak zorundasın.)',
            'You don’t have to pay. It’s free.\n(Ödemek zorunda değilsin. Bedava.)',
            'You mustn’t smoke here.\n(Burada sigara içmemelisin.)',
          ]),
        ],
      ),
    ],
  ),

  'B1-MODALS-02': const SubjectSummary(
    title: 'Modals: should / must / have to',
    worksheetIds: ['B1-MODALS-01', 'B1-MODALS-02'],
    sections: [
      SummarySection(
        title: 'Anlamlar',
        items: [
          SummaryList([
            'should → tavsiye',
            'must → güçlü zorunluluk (konuşanın “çok gerekli” hissi)',
            'have to → kural/dış zorunluluk (iş, okul, yasa)',
            'don’t have to → zorunlu değil (serbest)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula([
            'modal + V1',
            'Negative: shouldn’t / mustn’t / don’t have to',
          ]),
          SummaryText('mustn’t = yasak'),
          SummaryText('don’t have to = gerek yok'),
          SummaryExample([
            'You should study more.\n(Daha fazla ders çalışmalısın.)',
            'You have to wear a helmet.\n(Kask takmak zorundasın.)',
            'You don’t have to pay. It’s free.\n(Ödemek zorunda değilsin. Bedava.)',
            'You mustn’t smoke here.\n(Burada sigara içmemelisin.)',
          ]),
        ],
      ),
    ],
  ),

  // 3) Reported Speech (statements, say/tell, tense shift)
  'B1-REPORTED-01': const SubjectSummary(
    title: 'Reported Speech',
    worksheetIds: ['B1-REPORTED-01', 'B1-REPORTED-02', 'B1-REPORTED-03'],
    sections: [
      SummarySection(
        title: 'Temel fikir',
        items: [
          SummaryText('Birinin sözünü “dolaylı” anlatırız: He said (that)…'),
        ],
      ),
      SummarySection(
        title: 'Say vs Tell',
        items: [
          SummaryList([
            'say (to yoksa): He said (that)…',
            'tell + object: He told me (that)…',
          ]),
        ],
      ),
      SummarySection(
        title: 'Tense shift (en sık)',
        items: [
          SummaryList([
            'Present Simple → Past Simple',
            'Present Continuous → Past Continuous',
            'Present Perfect → Past Perfect',
            'will → would',
            'can → could',
          ]),
          SummaryExample([
            'Direct: “I’m tired.” → He said (that) he was tired.\n(Direct: “Yorgunum.” → Yorgun olduğunu söyledi.)',
            'Direct: “I have finished.” → She said she had finished.\n(Direct: “Bitirdim.” → Bitirdiğini söyledi.)',
            'Tell: He told me he was busy.\n(Bana meşgul olduğunu söyledi.)',
          ]),
          SummaryTip(['Reported clause’de do/does kullanılmaz.']),
        ],
      ),
    ],
  ),

  'B1-REPORTED-02': const SubjectSummary(
    title: 'Reported Speech',
    worksheetIds: ['B1-REPORTED-01', 'B1-REPORTED-02', 'B1-REPORTED-03'],
    sections: [
      SummarySection(
        title: 'Temel fikir',
        items: [
          SummaryText('Birinin sözünü “dolaylı” anlatırız: He said (that)…'),
        ],
      ),
      SummarySection(
        title: 'Say vs Tell',
        items: [
          SummaryList([
            'say (to yoksa): He said (that)…',
            'tell + object: He told me (that)…',
          ]),
        ],
      ),
      SummarySection(
        title: 'Tense shift (en sık)',
        items: [
          SummaryList([
            'Present Simple → Past Simple',
            'Present Continuous → Past Continuous',
            'Present Perfect → Past Perfect',
            'will → would',
            'can → could',
          ]),
          SummaryExample([
            'Direct: “I’m tired.” → He said (that) he was tired.\n(Direct: “Yorgunum.” → Yorgun olduğunu söyledi.)',
            'Direct: “I have finished.” → She said she had finished.\n(Direct: “Bitirdim.” → Bitirdiğini söyledi.)',
            'Tell: He told me he was busy.\n(Bana meşgul olduğunu söyledi.)',
          ]),
          SummaryTip(['Reported clause’de do/does kullanılmaz.']),
        ],
      ),
    ],
  ),

  'B1-REPORTED-03': const SubjectSummary(
    title: 'Reported Speech',
    worksheetIds: ['B1-REPORTED-01', 'B1-REPORTED-02', 'B1-REPORTED-03'],
    sections: [
      SummarySection(
        title: 'Temel fikir',
        items: [
          SummaryText('Birinin sözünü “dolaylı” anlatırız: He said (that)…'),
        ],
      ),
      SummarySection(
        title: 'Say vs Tell',
        items: [
          SummaryList([
            'say (to yoksa): He said (that)…',
            'tell + object: He told me (that)…',
          ]),
        ],
      ),
      SummarySection(
        title: 'Tense shift (en sık)',
        items: [
          SummaryList([
            'Present Simple → Past Simple',
            'Present Continuous → Past Continuous',
            'Present Perfect → Past Perfect',
            'will → would',
            'can → could',
          ]),
          SummaryExample([
            'Direct: “I’m tired.” → He said (that) he was tired.\n(Direct: “Yorgunum.” → Yorgun olduğunu söyledi.)',
            'Direct: “I have finished.” → She said she had finished.\n(Direct: “Bitirdim.” → Bitirdiğini söyledi.)',
            'Tell: He told me he was busy.\n(Bana meşgul olduğunu söyledi.)',
          ]),
          SummaryTip(['Reported clause’de do/does kullanılmaz.']),
        ],
      ),
    ],
  ),

  // 4) Conditionals: Zero & First
  'B1-COND-01': const SubjectSummary(
    title: 'Conditionals: Zero & First',
    sections: [
      SummarySection(
        title: 'Zero Conditional (genel gerçek / alışkanlık)',
        items: [
          SummaryFormula(['If + Present Simple, Present Simple']),
          SummaryExample([
            'If you heat ice, it melts.\n(Buzu ısıtırsan erir.)',
            'If I don’t sleep, I feel tired.\n(Uyumasam yorgun hissederim.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'First Conditional (gerçek gelecek ihtimali)',
        items: [
          SummaryFormula(['If + Present Simple, will + V1']),
          SummaryExample([
            'If it rains, we will stay home.\n(Yağmur yağarsa evde kalacağız.)',
            'If you study, you will pass.\n(Çalışırsan geçersin.)',
          ]),
          SummaryTip([
            'If cümlesinde will olmaz: ✅ If it rains, we will… (❌ If it will rain…)',
          ]),
        ],
      ),
    ],
  ),

  // 5) Present Perfect vs Past Simple (for/since/how long)
  'B1-PP-PS-02': const SubjectSummary(
    title: 'Present Perfect vs Past Simple',
    sections: [
      SummarySection(
        title: 'Present Perfect (başladı → hâlâ devam / etkisi var)',
        items: [
          SummaryFormula([
            'have/has + V3',
            'for + süre, since + başlangıç',
            'How long + have/has + S + V3?',
          ]),
          SummaryExample([
            'I have lived here for 5 years.\n(5 yıldır burada yaşıyorum.)',
            'She has worked here since 2021.\n(2021’den beri burada çalışıyor.)',
            'How long have you known him?\n(Onu ne zamandır tanıyorsun?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Past Simple (bitti, zamanı belli)',
        items: [
          SummaryText('İpuçları: yesterday / last… / in 2020 / ago'),
          SummaryExample([
            'I met him last week.\n(Onunla geçen hafta tanıştım.)',
          ]),
          SummaryTip(['for/since/how long → çoğu zaman Present Perfect ✅']),
        ],
      ),
    ],
  ),

  // 6) Relative Clauses (defining vs non-defining)
  'B1-REL-01': const SubjectSummary(
    title: 'Relative Clauses',
    sections: [
      SummarySection(
        title: 'Defining (ayırt eden — önemli bilgi)',
        items: [
          SummaryList([
            'Kimi/neyi kastettiğini seçtirir',
            'Genelde virgül yok',
          ]),
          SummaryExample([
            'The man who lives next door is friendly.\n(Yan dairede yaşayan adam arkadaş canlısıdır.)',
            'The book which you recommended is great.\n(Önerdiğin kitap harika.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Non-defining (ek bilgi — opsiyonel)',
        items: [
          SummaryList([
            '“Ekstra bilgi” verir',
            'Virgül kullanılır',
            '“that” genelde kullanılmaz',
          ]),
          SummaryExample([
            'My brother, who lives in Izmir, is a doctor.\n(İzmir’de yaşayan kardeşim doktordur.)',
            'This phone, which I bought yesterday, is expensive.\n(Dün aldığım bu telefon pahalı.)',
          ]),
          SummaryTip(['Virgül varsa → büyük ihtimal non-defining ✅']),
        ],
      ),
    ],
  ),

  // --- B2 ---

  // 1) Passive Advanced (perfect + modals)
  'B2-PASSIVE-02': const SubjectSummary(
    title: 'Passive Advanced',
    sections: [
      SummarySection(
        title: 'Present Perfect Passive',
        items: [
          SummaryFormula(['have/has been + V3']),
          SummaryExample([
            'The report has been finished.\n(Rapor tamamlandı.)',
            'The tickets have been sold.\n(Biletler satıldı.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Modal Passive',
        items: [
          SummaryFormula(['modal + be + V3']),
          SummaryText('Modals: must / should / can / might / will …'),
          SummaryExample([
            'The rules must be followed.\n(Kurallara uyulmalı.)',
            'The email should be sent today.\n(E-posta bugün gönderilmeli.)',
          ]),
          SummaryTip([
            'Perfect passive’de “been”, modal passive’de “be” kullanılır.',
          ]),
        ],
      ),
    ],
  ),

  // 2) Reported Speech (questions & commands)
  'B2-REPORTED-01': const SubjectSummary(
    title: 'Reported Speech (Questions & Commands)',
    sections: [
      SummarySection(
        title: 'Reported Questions',
        items: [
          SummaryText(
            'Soru cümlesinde do/does/did düşer, normal cümle dizilişi (S+V) gelir.',
          ),
          SummaryFormula([
            'Wh- questions: asked + (obj) + wh-word + S + V',
            'Yes/No questions: asked + (obj) + if / whether + S + V',
          ]),
          SummaryExample([
            '“Where do you live?” → He asked me where I lived.\n(Nerede yaşadığımı sordu.)',
            '“Do you like tea?” → She asked him if he liked tea.\n(Ona çay sevip sevmediğini sordu.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Reported Commands (Emir/Uyarı)',
        items: [
          SummaryFormula(['told/asked + object + (not) to + V1']),
          SummaryExample([
            '“Don’t touch it!” → She told me not to touch it.\n(Ona dokunmamamı söyledi.)',
            '“Open the window.” → He told us to open the window.\n(Bize pencereyi açmamızı söyledi.)',
          ]),
        ],
      ),
    ],
  ),

  // 3) Conditionals (Mixed & 3rd)
  'B2-COND-01': const SubjectSummary(
    title: 'Conditionals (Mixed & 3rd)',
    sections: [
      SummarySection(
        title: 'Third Conditional (geçmişte olmamış hayali durum)',
        items: [
          SummaryFormula(['If + Past Perfect (had V3), would have + V3']),
          SummaryExample([
            'If I had studied, I would have passed.\n(Çalışsaydım geçerdim.)',
            '(But I didn’t study, so I didn’t pass.)\n(Ama çalışmadım, bu yüzden geçemedim.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Mixed Conditional (geçmiş neden → şu an sonuç)',
        items: [
          SummaryFormula(['If + Past Perfect (had V3), would + V1']),
          SummaryExample([
            'If I had eaten breakfast, I wouldn’t be hungry now.\n(Kahvaltı yapsaydım şu an aç olmazdım.)',
          ]),
          SummaryTip([
            'Geçmiş pişmanlığı → Type 3',
            'Geçmişin bugüne etkisi → Mixed',
          ]),
        ],
      ),
    ],
  ),

  // 4) Relative Clauses (Advanced/Reduced)
  'B2-REL-01': const SubjectSummary(
    title: 'Relative Clauses (Advanced)',
    sections: [
      SummarySection(
        title: 'Reduced Relative Clauses (Kısaltma)',
        items: [
          SummaryList([
            'Active (yapan): V-ing',
            'Passive (yapılan): V3 (past participle)',
          ]),
          SummaryExample([
            'The boy who is sitting there… → The boy sitting there…\n(Orada oturan çocuk…)',
            'The book which was written by him… → The book written by him…\n(Onun tarafından yazılan kitap…)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Preposition + Relative Pronoun',
        items: [
          SummaryFormula([
            'to whom / with whom / in which / for which',
            '(Informal: who … with / which … in)',
          ]),
          SummaryExample([
            'Formal: The person with whom I spoke…\n(Konuştuğum kişi…)',
            'Informal: The person who I spoke with…\n(Konuştuğum kişi…)',
          ]),
        ],
      ),
    ],
  ),

  // 5) Verb Patterns (Gerund/Infinitive Advanced)
  'B2-VERB-01': const SubjectSummary(
    title: 'Verb Patterns (Gerund/Infinitive)',
    sections: [
      SummarySection(
        title: 'Verb + Gerund (V-ing)',
        items: [
          SummaryList([
            'avoid, enjoy, mind, suggest, recommend, finish, keep',
            'prepositions (in, on, at, of, for, about) + V-ing',
          ]),
          SummaryExample([
            'I enjoy swimming.\n(Yüzmekten keyif alırım.)',
            'He is good at drawing.\n(O çizimde iyidir.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Verb + Infinitive (to V1)',
        items: [
          SummaryList([
            'afford, agree, decide, hope, learn, manage, offer, promise, want, would like',
          ]),
          SummaryExample([
            'She decided to go.\n(Gitmeye karar verdi.)',
            'I want to help you.\n(Sana yardım etmek istiyorum.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Stop / Remember / Try (Anlam değişir)',
        items: [
          SummaryList([
            'Stop to do: Durup bir şey yapmak (amaç)',
            'Stop doing: Yapmayı bırakmak (eylemi kesmek)',
          ]),
          SummaryExample([
            'He stopped to smoke.\n(Sigara içmek için durdu.)',
            'He stopped smoking.\n(Sigarayı bıraktı.)',
          ]),
        ],
      ),
    ],
  ),

  // --- A1 Additional ---
  'A1-ART-01': const SubjectSummary(
    title: 'Articles: a/an/the',
    sections: [
      SummarySection(
        title: 'a / an (Indefinite - Belirsiz)',
        items: [
          SummaryFormula([
            'a + consonant sound (a book, a university)',
            'an + vowel sound (an apple, an hour)',
          ]),
          SummaryUsage([
            'İlk kez bahsederken: I saw a cat.',
            'Mesleklerde: She is an engineer.',
          ]),
          SummaryExample([
            'I have a brother.\n(Bir erkek kardeşim var.)',
            'He eats an apple every day.\n(Her gün bir elma yer.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'the (Definite - Belirli)',
        items: [
          SummaryUsage([
            'Hangi şey olduğu biliniyorsa (bahsi geçmişse)',
            'Dünyada tek olan şeyler (the sun, the moon)',
          ]),
          SummaryExample([
            'The cat I saw was black.\n(Gördüğüm o kedi siyahtı.)',
            'The sun rises in the east.\n(Güneş doğudan doğar.)',
          ]),
          SummaryTip([
            'Genelleme yaparken çoğul kullanırız, "the" kullanmayız:',
            'I like apples. (Genel olarak elma severim.)',
          ]),
        ],
      ),
    ],
  ),

  'A1-PREP-01': const SubjectSummary(
    title: 'Prepositions of Place',
    sections: [
      SummarySection(
        title: 'Konum Edatları',
        items: [
          SummaryList([
            'in: içinde',
            'on: üstünde (temas var)',
            'under: altında',
            'next to: bitişiğinde/yanında',
            'between: arasında',
          ]),
          SummaryExample([
            'The cat is in the box.\n(Kedi kutunun içinde.)',
            'The book is on the table.\n(Kitap masanın üstünde.)',
            'The shoes are under the bed.\n(Ayakkabılar yatağın altında.)',
            'I am sitting between Tom and Ali.\n(Tom ve Ali\'nin arasında oturuyorum.)',
          ]),
        ],
      ),
    ],
  ),

  'A1-POSS-01': const SubjectSummary(
    title: 'Possessives (Sahiplik)',
    sections: [
      SummarySection(
        title: 'Possessive Adjectives',
        items: [
          SummaryList([
            'my (benim), your (senin/sizin)',
            'his (onun-erkek), her (onun-kadın), its (onun-cansız/hayvan)',
            'our (bizim), their (onların)',
          ]),
          SummaryExample([
            'This is my car.\n(Bu benim arabam.)',
            'Her name is Ayşe.\n(Onun adı Ayşe.)',
          ]),
        ],
      ),
      SummarySection(
        title: '\'s (Apostrophe s)',
        items: [
          SummaryFormula(['Name/Noun + \'s + Object']),
          SummaryExample([
            'Tom\'s house.\n(Tom\'un evi.)',
            'My sister\'s cat.\n(Kız kardeşimin kedisi.)',
          ]),
          SummaryTip([
            'Çoğul -s ile bitiyorsa sadece kesme işareti:',
            'My parents\' room. (Anne babamın odası.)',
          ]),
        ],
      ),
    ],
  ),

  'A1-CAN-01': const SubjectSummary(
    title: 'Can / Can\'t',
    sections: [
      SummarySection(
        title: 'Ability (Yetenek)',
        items: [
          SummaryFormula(['(+) S + can + V1', '(-) S + can\'t + V1']),
          SummaryExample([
            'I can swim.\n(Yüzebilirim.)',
            'She can\'t speak French.\n(O Fransızca konuşamaz.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Requests (Rica)',
        items: [
          SummaryFormula(['Can you + V1 ...?']),
          SummaryExample([
            'Can you help me?\n(Bana yardım edebilir misin?)',
            'Can I open the window?\n(Pencereyi açabilir miyim?)',
          ]),
        ],
      ),
    ],
  ),

  // --- A2 Additional ---
  'A2-PPC-01': const SubjectSummary(
    title: 'Present Perfect Continuous',
    sections: [
      SummarySection(
        title: 'Formül ve Kullanım',
        items: [
          SummaryFormula(['have/has been + V-ing']),
          SummaryUsage([
            'Geçmişte başladı, hala devam ediyor (süreç vurgusu).',
            'Yakın zamanda bitmiş ama etkisi/belirtisi süren işler.',
          ]),
          SummaryExample([
            'I have been working for 3 hours.\n(3 saattir çalışıyorum - hala devam ediyor.)',
            'It has been raining all day.\n(Tüm gün yağmur yağıyor.)',
            'You look tired. Have you been running?\n(Yorgun görünüyorsun. Koşuyor muydun?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'for vs since',
        items: [
          SummaryList([
            'for + süre (for 2 hours, for a long time)',
            'since + başlangıç noktası (since 9 AM, since Monday)',
          ]),
        ],
      ),
    ],
  ),

  'A2-PP-01': const SubjectSummary(
    title: 'Past Perfect vs Past Simple',
    sections: [
      SummarySection(
        title: 'Zaman Sıralaması',
        items: [
          SummaryText('Geçmişte iki olay varsa:'),
          SummaryList([
            'Daha önce olan olay (1) → Past Perfect (had V3)',
            'Daha sonra olan olay (2) → Past Simple (V2)',
          ]),
          SummaryExample([
            'When I arrived at the station (2), the train had left (1).\n(İstasyona vardığımda tren gitmişti.)',
            'She realized she had lost her keys.\n(Anahtarlarını kaybettiğini fark etti.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Formül',
        items: [
          SummaryFormula(['(+) S + had + V3', '(-) S + hadn\'t + V3']),
        ],
      ),
    ],
  ),

  'A2-QUANT-01': const SubjectSummary(
    title: 'Quantifiers',
    sections: [
      SummarySection(
        title: 'Countable (Sayılabilen) ile',
        items: [
          SummaryList([
            'many (çok) - genelde olumsuz/soru',
            'a few (birkaç) - yeterli',
            'few (az) - yetersiz',
          ]),
          SummaryExample([
            'I have a few friends.\n(Birkaç arkadaşım var.)',
            'Are there many people?\n(Çok insan var mı?)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Uncountable (Sayılamayan) ile',
        items: [
          SummaryList([
            'much (çok) - genelde olumsuz/soru',
            'a little (biraz) - yeterli',
            'little (az) - yetersiz',
          ]),
          SummaryExample([
            'We have a little time.\n(Biraz vaktimiz var.)',
            'I don\'t have much money.\n(Çok param yok.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Her ikisi ile (Countable & Uncountable)',
        items: [
          SummaryList([
            'a lot of / lots of (çok) - genelde olumlu cümle',
            'some (biraz/birkaç) - olumlu',
            'any (hiç) - olumsuz/soru',
          ]),
          SummaryExample([
            'She has a lot of books.\n(Onun çok kitabı var.)',
            'There is a lot of water.\n(Çok su var.)',
          ]),
        ],
      ),
    ],
  ),

  'A2-ING-01': const SubjectSummary(
    title: 'Gerunds (-ing)',
    sections: [
      SummarySection(
        title: 'Kullanım Alanları',
        items: [
          SummaryUsage([
            'Özne olarak: Swimming is good for health.',
            'Edatlardan (preposition) sonra: I am good at drawing.',
            'Belirli fiillerden sonra: like, love, hate, enjoy, finish, stop, suggest...',
          ]),
          SummaryExample([
            'I enjoy reading.\n(Okumaktan keyif alırım.)',
            'She left without saying goodbye.\n(Hoşça kal demeden gitti.)',
          ]),
        ],
      ),
    ],
  ),

  // --- B1 Additional ---
  'B1-PPC-PS-01': const SubjectSummary(
    title: 'Past Perfect Continuous',
    sections: [
      SummarySection(
        title: 'Formül ve Kullanım',
        items: [
          SummaryFormula(['had been + V-ing']),
          SummaryUsage([
            'Geçmişte bir olaya kadar devam etmiş süreç.',
            'Geçmişteki bir durumun sebebini açıklarken.',
          ]),
          SummaryExample([
            'She was tired because she had been working all day.\n(Yorgundu çünkü tüm gün çalışıyordu.)',
            'It had been raining for hours when we woke up.\n(Uyandığımızda saatlerdir yağmur yağıyordu.)',
          ]),
        ],
      ),
    ],
  ),

  'B1-USED-01': const SubjectSummary(
    title: 'Used to',
    sections: [
      SummarySection(
        title: 'Geçmiş Alışkanlıklar',
        items: [
          SummaryUsage([
            'Geçmişte yaptığımız ama artık yapmadığımız şeyler.',
            'Geçmişteki durumlar.',
          ]),
          SummaryFormula([
            '(+) S + used to + V1',
            '(-) S + didn\'t use to + V1',
            '(?) Did + S + use to + V1?',
          ]),
          SummaryExample([
            'I used to smoke, but I stopped.\n(Eskiden sigara içerdim ama bıraktım.)',
            'She didn\'t use to like cheese.\n(Eskiden peynir sevmezdi.)',
          ]),
          SummaryTip([
            'Şimdiki alışkanlıklar için "usually" kullanılır, "use to" kullanılmaz.',
          ]),
        ],
      ),
    ],
  ),

  'B1-FUT-01': const SubjectSummary(
    title: 'Future Perfect vs Future Continuous',
    sections: [
      SummarySection(
        title: 'Future Continuous (Süreç)',
        items: [
          SummaryFormula(['will be + V-ing']),
          SummaryUsage(['Gelecekte belli bir anda yapıyor olacağımız işler.']),
          SummaryExample([
            'At 8 PM tonight, I will be watching TV.\n(Bu akşam 8\'de TV izliyor olacağım.)',
            'Don\'t call me at 10. I will be sleeping.\n(Beni 10\'da arama. Uyuyor olacağım.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Future Perfect (Tamamlanma)',
        items: [
          SummaryFormula(['will have + V3']),
          SummaryUsage(['Gelecekte belli bir andan önce bitmiş olacak işler.']),
          SummaryText('İpucu: "by" (itibariyle/kadar) edatı sık kullanılır.'),
          SummaryExample([
            'By 2030, I will have retired.\n(2030\'a kadar emekli olmuş olacağım.)',
            'We will have finished the project by Monday.\n(Pazartesiye kadar projeyi bitirmiş olacağız.)',
          ]),
        ],
      ),
    ],
  ),

  'B1-ART-01': const SubjectSummary(
    title: 'Articles (Advanced)',
    sections: [
      SummarySection(
        title: 'Genel vs Özel',
        items: [
          SummaryUsage([
            'Genel ifadelerde "the" kullanılmaz (çoğul veya sayılamayan).',
            'Özel/Belirli ifadelerde "the" kullanılır.',
          ]),
          SummaryExample([
            'I like music. (Genel)',
            'The music at the party was loud. (Partideki müzik - Özel)',
            'Children need love. (Tüm çocuklar)',
            'The children are in the garden. (Bizim çocuklar/bildiğimiz çocuklar)',
          ]),
        ],
      ),
      SummarySection(
        title: 'School / The School (Kurum vs Bina)',
        items: [
          SummaryList([
            'school, hospital, prison, university (amaç için gidiliyorsa "the" yok)',
            'the school, the hospital (bina olarak gidiliyorsa "the" var)',
          ]),
          SummaryExample([
            'He is in hospital. (Hasta olarak yatıyor.)',
            'I went to the hospital to visit him. (Ziyaretçi olarak gittim.)',
            'School starts at 8. (Eğitim)',
            'The school is near the park. (Bina)',
          ]),
        ],
      ),
    ],
  ),

  // --- B2 Additional ---
  'B2-PMOD-01': const SubjectSummary(
    title: 'Perfect Modals',
    sections: [
      SummarySection(
        title: 'Geçmişe Dair Çıkarımlar',
        items: [
          SummaryFormula(['Modal + have + V3']),
          SummaryList([
            'must have V3: %90 Eminim olmuştur (kuvvetli çıkarım)',
            'can\'t have V3: %90 Eminim olmamıştır (imkansız)',
            'might/could have V3: %50 Belki olmuştur (olasılık)',
          ]),
          SummaryExample([
            'He is late. He must have missed the bus.\n(Geç kaldı. Otobüsü kaçırmış olmalı.)',
            'She can\'t have seen me. I was hiding.\n(Beni görmüş olamaz. Saklanıyordum.)',
            'Where is my phone? I might have left it at work.\n(Telefonum nerede? İşte bırakmış olabilirim.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Geçmiş Eleştiri / Pişmanlık',
        items: [
          SummaryList([
            'should have V3: Yapmalıydın (ama yapmadın)',
            'shouldn\'t have V3: Yapmamalıydın (ama yaptın)',
          ]),
          SummaryExample([
            'You should have studied more.\n(Daha çok çalışmalıydın.)',
            'I shouldn\'t have eaten so much.\n(O kadar çok yememeliydim.)',
          ]),
        ],
      ),
    ],
  ),

  'B2-WISH-01': const SubjectSummary(
    title: 'Wish / If only',
    sections: [
      SummarySection(
        title: 'Present Wish (Şu anki pişmanlık)',
        items: [
          SummaryFormula(['wish + Past Simple']),
          SummaryText(
            'Gerçek durumun tersini dileriz. (Tense bir derece geçmişe gider)',
          ),
          SummaryExample([
            'I wish I were rich. (I am not rich.)\n(Keşke zengin olsaydım.)',
            'I wish I didn\'t have to work today.\n(Keşke bugün çalışmak zorunda olmasaydım.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Past Wish (Geçmiş pişmanlık)',
        items: [
          SummaryFormula(['wish + Past Perfect (had V3)']),
          SummaryExample([
            'I wish I had studied harder.\n(Keşke daha çok çalışsaydım.)',
            'I wish I hadn\'t said that.\n(Keşke onu söylemeseydim.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Wish + Would (Şikayet)',
        items: [
          SummaryUsage([
            'Birinin bir şeyi yapmasını/yapmamasını isterken (şikayet).',
          ]),
          SummaryExample([
            'I wish you would stop smoking.\n(Keşke sigara içmeyi bıraksan.)',
            'I wish it would stop raining.\n(Keşke yağmur dursa.)',
          ]),
        ],
      ),
    ],
  ),

  'B2-INV-01': const SubjectSummary(
    title: 'Inversion (Devrik Cümle)',
    sections: [
      SummarySection(
        title: 'Negative Adverbials ile',
        items: [
          SummaryUsage([
            'Vurgu yapmak için olumsuz zarf başa gelir, cümle soru formatına (devrik) döner.',
          ]),
          SummaryList([
            'Never, Rarely, Seldom, Hardly, No sooner...',
            'Not only... but also...',
            'Under no circumstances...',
          ]),
          SummaryFormula(['Adverb + Auxiliary Verb + S + V']),
          SummaryExample([
            'Normal: I have never seen such a thing.',
            'Inversion: Never have I seen such a thing.\n(Hayatımda asla böyle bir şey görmedim.)',
            'Rarely do we go out.\n(Nadiren dışarı çıkarız.)',
            'Not only is he smart, but also he is funny.\n(O sadece zeki değil, aynı zamanda komiktir.)',
          ]),
        ],
      ),
    ],
  ),

  'B2-LINK-01': const SubjectSummary(
    title: 'Linking Words',
    sections: [
      SummarySection(
        title: 'Contrast (Zıtlık)',
        items: [
          SummaryList([
            'Although / Even though + Cümle (Rağmen)',
            'Despite / In spite of + Noun/V-ing (Rağmen)',
            'However / Nevertheless (Ama/Yine de - virgüle dikkat)',
            'Whereas / While (Oysa ki - kıyaslama)',
          ]),
          SummaryExample([
            'Although it rained, we went out.\n(Yağmur yağmasına rağmen dışarı çıktık.)',
            'Despite the rain, we went out.\n(Yağmura rağmen dışarı çıktık.)',
            'It rained. However, we went out.\n(Yağmur yağdı. Yine de dışarı çıktık.)',
            'Tom is rich, whereas Jack is poor.\n(Tom zengin, oysa ki Jack fakir.)',
          ]),
        ],
      ),
      SummarySection(
        title: 'Reason & Result (Sebep & Sonuç)',
        items: [
          SummaryList([
            'Because / Since / As + Cümle (Çünkü)',
            'Because of / Due to + Noun (Yüzünden)',
            'Therefore / As a result (Bu yüzden)',
          ]),
          SummaryExample([
            'We stayed home because it was raining.',
            'We stayed home due to the rain.',
            'It was raining. Therefore, we stayed home.',
          ]),
        ],
      ),
    ],
  ),
};
