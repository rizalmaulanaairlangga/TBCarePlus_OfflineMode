import 'app_strings.dart';

/// Offline hardcoded translations for TBC domain content.
/// Keys are Indonesian base values (as stored in JSON). English values provided.
class TbContentL10n {
  static const Map<String, String> tbTypeNameEn = {
    'TBC Paru': 'Pulmonary TB',
    'TBC Kelenjar': 'Lymph Node TB',
    'TBC Payudara': 'Breast TB',
    'TBC Tulang Belakang': 'Spinal TB',
    'Kategori 1': 'Category 1',
  };

  static const Map<String, String> symptomNameEn = {
    'Batuk terus-menerus dan berdahak selama tiga minggu/lebih':
        'Persistent cough with phlegm for three weeks or more',
    'Dahak bercampur darah/batuk darah': 'Blood-tinged sputum / coughing blood',
    'Demam yang berlangsung lama': 'Prolonged fever',
    'Sesak nafas dan nyeri dada': 'Shortness of breath and chest pain',
    'Penurunan nafsu makan': 'Decreased appetite',
    'Penurunan berat badan': 'Weight loss',
    'Rasa kurang enak badan/malaise, lemah': 'General malaise / weakness',
    'Berkeringat di malam hari walaupun tidak melakukan apa-apa':
        'Night sweats even without activity',
    'Munculnya benjolan pada kelenjar (leher, ketiak, sela paha)':
        'Lumps in lymph glands (neck, armpit, groin)',
    'Ada tanda-tanda radang di sekitar benjolan kelenjar':
        'Signs of inflammation around lymph lumps',
    'Benjolan kelenjar mudah digerakkan': 'Movable lymph lumps',
    'Benjolan kelenjar terasa kenyal': 'Rubbery lymph lumps',
    'Pembesaran benjolan kelenjar yang memburuk': 'Progressively enlarging lymph lumps',
    'Benjolan pecah dan mengeluarkan nanah': 'Ruptured lumps discharging pus',
    'Luka pada kulit akibat pecahnya benjolan kelenjar':
        'Skin lesions from ruptured lymph lumps',
    'Timbulnya benjolan di payudara': 'Lumps in the breast',
    'Rasa nyeri di bagian payudara': 'Breast pain',
    'Radang di sekitar benjolan payudara': 'Inflammation around breast lumps',
    'Nyeri atau kaku pada punggung': 'Back pain or stiffness',
    'Enggan menggerakkan punggung': 'Reluctance to move the back',
    'Menolak membungkuk / mengangkat barang': 'Refusal to bend / lift objects',
    'Nyeri punggung berkurang saat istirahat': 'Back pain eases with rest',
    'Benjolan di tulang belakang': 'Lumps in the spine',
  };

  static const Map<String, String> symptomDescEn = {
    'Batuk berdahak yang berlangsung lama dan tidak membaik dalam tiga minggu atau lebih.':
        'Productive cough that persists and does not improve for three weeks or more.',
    'Dahak terlihat bercampur darah atau keluar darah saat batuk.':
        'Sputum appears mixed with blood or blood comes out when coughing.',
    'Demam berulang atau menetap dalam waktu lama tanpa penyebab yang jelas.':
        'Recurrent or persistent fever over a long time without clear cause.',
    'Napas terasa berat atau pendek, disertai rasa nyeri atau tidak nyaman di dada.':
        'Breathing feels heavy or short, with pain or discomfort in the chest.',
    'Keinginan makan menurun dibandingkan kondisi biasanya.':
        'Appetite decreased compared to usual condition.',
    'Berat badan turun tanpa sedang menjalani program diet atau penyebab yang jelas.':
        'Weight loss without dieting or clear cause.',
    'Tubuh terasa tidak fit, lemah, lesu, atau mudah lelah dalam aktivitas harian.':
        'Body feels unwell, weak, sluggish, or easily tired in daily activities.',
    'Keringat berlebih muncul pada malam hari meskipun tidak sedang beraktivitas berat.':
        'Excessive sweating at night even without strenuous activity.',
    'Terdapat benjolan di area kelenjar seperti leher, ketiak, atau sela paha.':
        'Lumps found in glandular areas such as neck, armpit, or groin.',
    'Area sekitar benjolan tampak meradang, misalnya kemerahan, hangat, nyeri, atau bengkak.':
        'Area around lumps appears inflamed — redness, warmth, pain, or swelling.',
    'Benjolan terasa dapat bergeser saat disentuh atau ditekan perlahan.':
        'Lumps feel movable when touched or pressed gently.',
    'Benjolan memiliki tekstur kenyal saat diraba.':
        'Lumps have a rubbery texture when palpated.',
    'Ukuran benjolan bertambah besar atau keluhan terasa semakin berat dari waktu ke waktu.':
        'Lumps grow larger or complaints worsen over time.',
    'Benjolan terbuka atau pecah dan mengeluarkan cairan seperti nanah.':
        'Lumps open or rupture and discharge pus-like fluid.',
    'Muncul luka di kulit setelah benjolan pecah atau mengeluarkan cairan.':
        'Skin lesions appear after lumps rupture or discharge fluid.',
    'Terdapat benjolan pada area payudara yang sebelumnya tidak ada.':
        'Lumps found in the breast area that were not there before.',
    'Payudara terasa nyeri, sakit, atau tidak nyaman.':
        'Breast feels painful or uncomfortable.',
    'Area sekitar benjolan payudara tampak meradang, seperti kemerahan, bengkak, hangat, atau nyeri.':
        'Area around breast lumps appears inflamed — redness, swelling, warmth, or pain.',
    'Punggung terasa nyeri, kaku, atau sulit digerakkan dengan nyaman.':
        'Back feels painful, stiff, or difficult to move comfortably.',
    'Menghindari gerakan punggung karena terasa nyeri, kaku, atau tidak nyaman.':
        'Avoiding back movement due to pain, stiffness, or discomfort.',
    'Kesulitan atau enggan membungkuk dan mengangkat barang karena keluhan pada punggung.':
        'Difficulty or reluctance to bend and lift objects due to back complaints.',
    'Nyeri punggung terasa lebih ringan ketika beristirahat.':
        'Back pain feels lighter when resting.',
    'Terdapat benjolan atau perubahan bentuk yang terasa atau terlihat di area tulang belakang.':
        'Lumps or shape changes felt or visible in the spinal area.',
  };

  static const Map<String, String> questionTextEn = {
    'Batuk terus-menerus dan berdahak selama tiga minggu atau lebih':
        'Persistent cough with phlegm for three weeks or more',
    'Dahak bercampur darah atau batuk darah': 'Blood-tinged sputum or coughing blood',
    'Demam yang berlangsung lama': 'Prolonged fever',
    'Sesak nafas dan nyeri dada': 'Shortness of breath and chest pain',
    'Penurunan nafsu makan': 'Decreased appetite',
    'Penurunan berat badan': 'Weight loss',
    'Rasa kurang enak badan, malaise, atau lemah': 'General malaise or weakness',
    'Berkeringat di malam hari walaupun tidak melakukan aktivitas berat':
        'Night sweats even without strenuous activity',
    'Munculnya benjolan pada bagian yang mengalami gangguan kelenjar seperti leher, sela paha, serta ketiak':
        'Lumps in affected glandular areas such as neck, groin, and armpit',
    'Adanya tanda radang di daerah sekitar benjolan kelenjar':
        'Signs of inflammation around lymph lumps',
    'Benjolan kelenjar mudah digerakkan': 'Movable lymph lumps',
    'Benjolan kelenjar terasa kenyal': 'Rubbery lymph lumps',
    'Membesarnya benjolan kelenjar yang menyebabkan hari demi hari kondisinya semakin memburuk dan merusak tubuh':
        'Enlarging lymph lumps that worsen day by day',
    'Benjolan kelenjar pecah dan mengeluarkan cairan seperti nanah yang kotor':
        'Ruptured lymph lumps discharging foul pus-like fluid',
    'Terdapat luka pada jaringan kulit atau kulit yang disebabkan pecahnya benjolan kelenjar getah bening':
        'Skin lesions caused by ruptured lymph nodes',
    'Timbulnya benjolan di payudara': 'Lumps in the breast',
    'Rasa nyeri di bagian payudara': 'Pain in the breast',
    'Adanya tanda radang di sekitar benjolan yang timbul di payudara':
        'Signs of inflammation around breast lumps',
    'Rasa nyeri atau sakit pada bagian punggung atau mengalami kekakuan punggung':
        'Back pain or stiffness',
    'Penderita enggan menggerakkan punggungnya': 'Reluctance to move the back',
    'Penderita menolak untuk membungkuk atau mengangkat barang dari lantai karena akan menekuk lututnya agar punggung tetap lurus':
        'Refusal to bend or lift objects — bending knees to keep back straight',
    'Rasa nyeri atau sakit pada punggung berkurang ketika penderita beristirahat':
        'Back pain eases when resting',
    'Timbulnya benjolan di bagian punggung atau tulang belakang':
        'Lumps on the back or spine',
  };

  // Risk level translations (id -> en) - descriptions & recommendations
  static const Map<String, String> riskDescEn = {
    'Persentase hasil berada pada rentang risiko rendah berdasarkan perhitungan certainty factor.':
        'Result percentage falls in low-risk range based on certainty factor calculation.',
    'Persentase hasil berada pada rentang risiko sedang berdasarkan perhitungan certainty factor.':
        'Result percentage falls in medium-risk range based on certainty factor calculation.',
    'Persentase hasil berada pada rentang risiko tinggi berdasarkan perhitungan certainty factor.':
        'Result percentage falls in high-risk range based on certainty factor calculation.',
  };

  static const Map<String, String> riskRecoEn = {
    'Pantau kondisi kesehatan dan lakukan pemeriksaan ulang jika gejala menetap atau memburuk.':
        'Monitor your health and re-examine if symptoms persist or worsen.',
    'Disarankan berkonsultasi dengan tenaga kesehatan, terutama jika batuk, demam, atau berat badan turun berlangsung lama.':
        'Consult a health worker, especially if cough, fever, or weight loss persists.',
    'Segera lakukan pemeriksaan ke fasilitas kesehatan untuk evaluasi lebih lanjut.':
        'Seek immediate examination at a health facility for further evaluation.',
    'Pantau benjolan atau keluhan lain, dan periksa jika ukuran membesar atau muncul tanda radang.':
        'Monitor lumps or other complaints, and check if size increases or inflammation appears.',
    'Disarankan berkonsultasi dengan tenaga kesehatan jika benjolan menetap, membesar, atau terasa nyeri.':
        'Consult a health worker if lumps persist, enlarge, or become painful.',
    'Segera lakukan pemeriksaan medis, terutama jika benjolan pecah, bernanah, atau terus membesar.':
        'Seek immediate medical examination, especially if lumps rupture, produce pus, or keep enlarging.',
    'Pantau perubahan pada payudara dan lakukan pemeriksaan jika keluhan menetap.':
        'Monitor breast changes and examine if complaints persist.',
    'Disarankan berkonsultasi dengan tenaga kesehatan jika terdapat benjolan, nyeri, atau tanda radang.':
        'Consult a health worker if lumps, pain, or inflammation are present.',
    'Segera lakukan pemeriksaan medis untuk evaluasi benjolan atau radang pada payudara.':
        'Seek immediate medical evaluation for lumps or inflammation in the breast.',
    'Pantau nyeri atau kaku pada punggung dan periksa jika keluhan tidak membaik.':
        'Monitor back pain or stiffness and check if it does not improve.',
    'Disarankan berkonsultasi dengan tenaga kesehatan jika nyeri punggung menetap atau mengganggu aktivitas.':
        'Consult a health worker if back pain persists or interferes with activity.',
    'Segera lakukan pemeriksaan medis, terutama jika nyeri berat, kaku, atau ada benjolan di tulang belakang.':
        'Seek immediate medical examination, especially for severe pain, stiffness, or spinal lumps.',
  };

  static const Map<String, String> riskTitleEn = {
    'Low Risk': 'Low Risk',
    'Medium Risk': 'Medium Risk',
    'High Risk': 'High Risk',
  };

  static String tbType(String idValue, AppLocale locale) {
    if (locale == AppLocale.en) return tbTypeNameEn[idValue] ?? idValue;
    return idValue;
  }

  static String symptomName(String idValue, AppLocale locale) {
    if (locale == AppLocale.en) return symptomNameEn[idValue] ?? idValue;
    return idValue;
  }

  static String symptomDesc(String? idValue, AppLocale locale) {
    if (idValue == null) return '';
    if (locale == AppLocale.en) return symptomDescEn[idValue] ?? idValue;
    return idValue;
  }

  static String questionText(String idValue, AppLocale locale) {
    if (locale == AppLocale.en) return questionTextEn[idValue] ?? idValue;
    return idValue;
  }

  static String riskDesc(String? idValue, AppLocale locale) {
    if (idValue == null) return '';
    if (locale == AppLocale.en) return riskDescEn[idValue] ?? idValue;
    return idValue;
  }

  static String riskReco(String? idValue, AppLocale locale) {
    if (idValue == null) return '';
    if (locale == AppLocale.en) return riskRecoEn[idValue] ?? idValue;
    return idValue;
  }

  static String riskTitle(String idValue, AppLocale locale) {
    // titles are already English in JSON, but keep for consistency
    if (locale == AppLocale.id) {
      // map English title to Indonesian if needed
      if (idValue == 'Low Risk') return 'Risiko Rendah';
      if (idValue == 'Medium Risk') return 'Risiko Sedang';
      if (idValue == 'High Risk') return 'Risiko Tinggi';
    }
    return idValue;
  }
}
