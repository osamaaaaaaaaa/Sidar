import { initializeApp, getApps } from 'https://www.gstatic.com/firebasejs/12.0.0/firebase-app.js';
import { getAI, getGenerativeModel, GoogleAIBackend } from 'https://www.gstatic.com/firebasejs/12.0.0/firebase-ai.js';

(function () {
  const cfg = window.SIDAR_CONFIG || {};
  const firebaseCfg = cfg.FIREBASE_CONFIG || {};
  const modelName = cfg.FIREBASE_GEMINI_MODEL || 'gemini-2.5-flash';

  function hasFirebaseConfig() {
    return !!(
      firebaseCfg.apiKey &&
      firebaseCfg.projectId &&
      firebaseCfg.appId &&
      !String(firebaseCfg.apiKey).includes('YOUR_') &&
      !String(firebaseCfg.projectId).includes('YOUR_') &&
      !String(firebaseCfg.appId).includes('YOUR_')
    );
  }

  function assertConfigured() {
    if (!cfg.USE_FIREBASE_AI_LOGIC) {
      throw new Error('Analysis is disabled in config.');
    }
    if (!hasFirebaseConfig()) {
      throw new Error('Analysis is not configured yet. Add your keys in js/config.js.');
    }
  }

  function readFileAsBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        try {
          const data = String(reader.result || '');
          resolve(data.includes(',') ? data.split(',')[1] : data);
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  async function fileToGenerativePart(file) {
    return {
      inlineData: {
        data: await readFileAsBase64(file),
        mimeType: file.type || 'image/jpeg',
      },
    };
  }

  function buildPrompt(formData, lang, catalog = {}) {
    const isAr = lang === 'ar';
    const verifiedCatalog = JSON.stringify({
      products: (catalog.products || []).slice(0, 20).map(({ id, name, brand, category, concerns, skin_types }) => ({ id, name, brand, category, concerns, skin_types })),
      doctors: (catalog.doctors || []).slice(0, 12).map(({ id, full_name, specialization, country, city, clinic_hospital, concerns }) => ({ id, full_name, specialization, country, city, clinic_hospital, concerns })),
    });
    return isAr
      ? `أنت مساعد مراجعة مرئية داخل منصة SIDAR.
حلل الصور والمعلومات المرفوعة بصياغة واضحة ومطمئنة ومناسبة للمستخدم العادي.
ممنوع تقديم تشخيص طبي نهائي أو وصف دواء أو ادعاء يقين كامل.
اعتمد فقط على ما يظهر بصريًا وما أدخله المستخدم.
أعد النتيجة كـ JSON فقط وبدون أي نص إضافي، وطبق هذا الشكل حرفيًا:
{
  "title": string,
  "analysis_target": "skin"|"hair"|"both",
  "ai_confidence": string,
  "case_priority": "High"|"Moderate"|"Low",
  "image_quality": "Good"|"Medium"|"Low",
  "visible_patterns": string[],
  "guidance": string,
  "next_steps": string[],
  "reasons": string[],
  "overall_score": number,
  "hydration_score": number,
  "pore_clarity_score": number,
  "fine_lines_score": number,
  "overall_tone_score": number,
  "hair_density_score": number,
  "hair_texture_score": number,
  "hair_strength_score": number,
  "scalp_health_score": number,
  "morning_routine": string[],
  "evening_routine": string[],
  "natural_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "commercial_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "suggested_product_ids": string[],
  "suggested_doctor_ids": string[],
  "disclaimer": string
}
شروط الكتابة:
- title قصير وطبيعي ومناسب لواجهة مستخدم.
- visible_patterns من 2 إلى 5 نقاط قصيرة.
- guidance فقرة واحدة عملية وواضحة.
- next_steps من 3 إلى 5 خطوات قابلة للتنفيذ.
- reasons من 2 إلى 4 أسباب قصيرة تشرح سبب التقييم.
- overall_score ودرجات المؤشرات كلها أرقام من 0 إلى 100.
- إذا كانت الحالة تخص الشعر أو الفروة فاملأ hair_density_score وhair_texture_score وhair_strength_score وscalp_health_score.
- إذا كانت الحالة تخص البشرة فاملأ hydration_score وpore_clarity_score وfine_lines_score وoverall_tone_score.
- اجعل الدرجات غير المستخدمة = 0 فقط إذا لم تنطبق على نوع الحالة.
- morning_routine و evening_routine من 3 إلى 5 خطوات.
- اقتراحات المنتجات الطبيعية والتجارية من 2 إلى 4 عناصر لكل قسم.
- كل منتج يجب أن يحتوي على: name و desc و price و image.
- price تكون نصًا مختصرًا مثل "$18.99".
- image يجب أن يكون رابط صورة مباشر عام يبدأ بـ "http://" أو "https://".
- ممنوع إرجاع مسارات محلية أو روابط assets.
- استخدم روابط صور حقيقية للمنتج قدر الإمكان.
- ai_confidence تكون نسبة مئوية نصية مثل 88%.
- إذا كانت الصور غير واضحة اخفض image_quality واذكر ذلك في guidance.
- اختر من معرّفات المنتجات والأطباء في الكتالوج المعتمد أدناه فقط. لا تخترع أسماء أو معرفات. أعد من 0 إلى 4 معرفات لكل نوع.
- استخدم العربية فقط في القيم النصية.
بيانات الحالة:
- نوع المراجعة: ${formData.scan_type}
- المنطقة: ${formData.body_location}
- المدة: ${formData.duration}
- الشدة: ${formData.severity}
- نوع المشكلة: ${formData.issue_type || 'غير محدد'}
- نوع البشرة: ${formData.skin_type_context || 'غير محدد'}
- الأعراض: ${(formData.symptoms || []).join(', ') || 'لا يوجد'}
- الملاحظات: ${formData.notes || 'لا يوجد'}
الكتالوج المعتمد (بيانات فعلية من قاعدة SIDAR): ${verifiedCatalog}`
      : `You are the visual review assistant inside SIDAR.
Analyze the uploaded images and user context using calm, clear, patient-facing language.
Do not provide a final medical diagnosis, do not prescribe medication, and do not claim certainty.
Use only what is visibly present in the images and what the user reported.
Return JSON only with no markdown and no extra text. Use exactly this shape:
{
  "title": string,
  "analysis_target": "skin"|"hair"|"both",
  "ai_confidence": string,
  "case_priority": "High"|"Moderate"|"Low",
  "image_quality": "Good"|"Medium"|"Low",
  "visible_patterns": string[],
  "guidance": string,
  "next_steps": string[],
  "reasons": string[],
  "overall_score": number,
  "hydration_score": number,
  "pore_clarity_score": number,
  "fine_lines_score": number,
  "overall_tone_score": number,
  "hair_density_score": number,
  "hair_texture_score": number,
  "hair_strength_score": number,
  "scalp_health_score": number,
  "morning_routine": string[],
  "evening_routine": string[],
  "natural_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "commercial_product_suggestions": [{"name": string, "desc": string, "price": string, "image": string}],
  "suggested_product_ids": string[],
  "suggested_doctor_ids": string[],
  "disclaimer": string
}
Rules:
- title should be short, natural, and suitable for a user interface.
- visible_patterns should contain 2 to 5 concise findings.
- guidance should be one practical paragraph.
- next_steps should contain 3 to 5 actionable steps.
- reasons should contain 2 to 4 concise reasons behind the evaluation.
- overall_score and metric scores must be numeric values between 0 and 100.
- For hair/scalp cases, fill hair_density_score, hair_texture_score, hair_strength_score, and scalp_health_score.
- For skin cases, fill hydration_score, pore_clarity_score, fine_lines_score, and overall_tone_score.
- Set non-applicable metric scores to 0 only when they do not match the case type.
- morning_routine and evening_routine should each contain 3 to 5 steps.
- natural and commercial product suggestions should each contain 2 to 4 items.
- each product object must include: name, desc, price, and image.
- price must be a short string like "$18.99".
- image must be a direct public network image URL that starts with "http://" or "https://".
- do not return local asset paths.
- use real product packshot-style image URLs when possible.
- ai_confidence must be a string percentage like 88%.
- If the images are unclear, lower image_quality and mention that in guidance.
- Select only IDs from the verified SIDAR catalog below. Never invent names or IDs. Return 0 to 4 IDs per type.
- Use English only for all textual values.
Case details:
- Review type: ${formData.scan_type}
- Body area: ${formData.body_location}
- Duration: ${formData.duration}
- Severity: ${formData.severity}
- Issue type: ${formData.issue_type || 'not specified'}
- Skin type: ${formData.skin_type_context || 'not specified'}
- Symptoms: ${(formData.symptoms || []).join(', ') || 'none'}
- Notes: ${formData.notes || 'none'}
Verified SIDAR catalog (real database records): ${verifiedCatalog}`;
  }

  function responseSchema() {
    return {
      type: 'object',
      properties: {
        title: { type: 'string' },
        analysis_target: { type: 'string', enum: ['skin', 'hair', 'both'] },
        ai_confidence: { type: 'string' },
        case_priority: { type: 'string', enum: ['High', 'Moderate', 'Low'] },
        image_quality: { type: 'string', enum: ['Good', 'Medium', 'Low'] },
        visible_patterns: { type: 'array', items: { type: 'string' } },
        guidance: { type: 'string' },
        next_steps: { type: 'array', items: { type: 'string' } },
        reasons: { type: 'array', items: { type: 'string' } },
        overall_score: { type: 'number' },
        hydration_score: { type: 'number' },
        pore_clarity_score: { type: 'number' },
        fine_lines_score: { type: 'number' },
        overall_tone_score: { type: 'number' },
        hair_density_score: { type: 'number' },
        hair_texture_score: { type: 'number' },
        hair_strength_score: { type: 'number' },
        scalp_health_score: { type: 'number' },
        morning_routine: { type: 'array', items: { type: 'string' } },
        evening_routine: { type: 'array', items: { type: 'string' } },
        natural_product_suggestions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              desc: { type: 'string' },
              price: { type: 'string' },
              image: { type: 'string' },
            },
            required: ['name', 'desc', 'price', 'image'],
          }
        },
        commercial_product_suggestions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              desc: { type: 'string' },
              price: { type: 'string' },
              image: { type: 'string' },
            },
            required: ['name', 'desc', 'price', 'image'],
          }
        },
        suggested_product_ids: { type: 'array', items: { type: 'string' } },
        suggested_doctor_ids: { type: 'array', items: { type: 'string' } },
        disclaimer: { type: 'string' },
      },
      required: [
        'title',
        'analysis_target',
        'ai_confidence',
        'case_priority',
        'image_quality',
        'visible_patterns',
        'guidance',
        'next_steps',
        'reasons',
        'overall_score',
        'morning_routine',
        'evening_routine',
        'natural_product_suggestions',
        'commercial_product_suggestions',
        'disclaimer'
      ],
    };
  }

  function normalizeResult(parsed, lang) {
    if (!parsed || typeof parsed !== 'object') {
      throw new Error(lang === 'ar' ? 'خدمة التحليل أعادت نتيجة غير صالحة.' : 'The analysis service returned an invalid response.');
    }

    const requiredText = ['title', 'ai_confidence', 'guidance', 'disclaimer'];
    for (const key of requiredText) {
      if (typeof parsed[key] !== 'string' || !parsed[key].trim()) {
        throw new Error(lang === 'ar' ? `نتيجة التحليل ناقصة في الحقل: ${key}` : `The analysis result is missing the field: ${key}`);
      }
    }

    const requireArray = (value, key) => {
      if (!Array.isArray(value) || !value.length) {
        throw new Error(lang === 'ar' ? `نتيجة التحليل ناقصة في الحقل: ${key}` : `The analysis result is missing the field: ${key}`);
      }
      return value.filter(Boolean);
    };

    const toScore = (value) => {
      const n = Number(value);
      if (!Number.isFinite(n)) return null;
      return Math.max(0, Math.min(100, n));
    };

    const normalizeProducts = (items, key) =>
      requireArray(items, key)
        .slice(0, 4)
        .map((item) => ({
          name: String(item?.name || '').trim(),
          desc: String(item?.desc || '').trim(),
          price: String(item?.price || '').trim(),
          image: /^https?:\/\//i.test(String(item?.image || '').trim())
            ? String(item.image).trim()
            : 'https://via.placeholder.com/400x400?text=Product',
        }));

    return {
      title: parsed.title.trim(),
      analysis_target: ['skin', 'hair', 'both'].includes(parsed.analysis_target) ? parsed.analysis_target : 'skin',
      ai_confidence: parsed.ai_confidence.trim(),
      case_priority: ['High', 'Moderate', 'Low'].includes(parsed.case_priority) ? parsed.case_priority : 'Moderate',
      image_quality: ['Good', 'Medium', 'Low'].includes(parsed.image_quality) ? parsed.image_quality : 'Medium',
      visible_patterns: requireArray(parsed.visible_patterns, 'visible_patterns').slice(0, 5),
      guidance: parsed.guidance.trim(),
      next_steps: requireArray(parsed.next_steps, 'next_steps').slice(0, 5),
      reasons: requireArray(parsed.reasons, 'reasons').slice(0, 4),
      overall_score: toScore(parsed.overall_score),
      hydration_score: toScore(parsed.hydration_score),
      pore_clarity_score: toScore(parsed.pore_clarity_score),
      fine_lines_score: toScore(parsed.fine_lines_score),
      overall_tone_score: toScore(parsed.overall_tone_score),
      hair_density_score: toScore(parsed.hair_density_score),
      hair_texture_score: toScore(parsed.hair_texture_score),
      hair_strength_score: toScore(parsed.hair_strength_score),
      scalp_health_score: toScore(parsed.scalp_health_score),
      morning_routine: requireArray(parsed.morning_routine, 'morning_routine').slice(0, 5),
      evening_routine: requireArray(parsed.evening_routine, 'evening_routine').slice(0, 5),
      natural_product_suggestions: normalizeProducts(parsed.natural_product_suggestions, 'natural_product_suggestions'),
      commercial_product_suggestions: normalizeProducts(parsed.commercial_product_suggestions, 'commercial_product_suggestions'),
      suggested_product_ids: Array.isArray(parsed.suggested_product_ids) ? parsed.suggested_product_ids.map(String).slice(0, 4) : [],
      suggested_doctor_ids: Array.isArray(parsed.suggested_doctor_ids) ? parsed.suggested_doctor_ids.map(String).slice(0, 4) : [],
      disclaimer: parsed.disclaimer.trim(),
    };
  }

  function extractJson(text) {
    const trimmed = String(text || '').trim();
    if (!trimmed) throw new Error('Empty response from the analysis service.');
    try {
      return JSON.parse(trimmed);
    } catch (_) {
      const start = trimmed.indexOf('{');
      const end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return JSON.parse(trimmed.slice(start, end + 1));
      }
      throw new Error('Could not parse the analysis response as JSON.');
    }
  }

  let model = null;
  async function getModel() {
    if (model) return model;
    assertConfigured();
    const app = getApps().length ? getApps()[0] : initializeApp(firebaseCfg);
    const ai = getAI(app, { backend: new GoogleAIBackend() });
    model = getGenerativeModel(ai, {
      model: modelName,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: 'application/json',
        responseSchema: responseSchema(),
      },
    });
    return model;
  }

  async function generateWithFirebase(formData, files, lang = 'en', catalog = {}) {
    if (!files?.length) {
      throw new Error(lang === 'ar' ? 'يرجى رفع صورة واحدة على الأقل.' : 'Please upload at least one image.');
    }

    try {
      const liveModel = await getModel();
      const imageParts = await Promise.all(files.map(fileToGenerativePart));
      const prompt = buildPrompt(formData, lang, catalog);
      const response = await liveModel.generateContent([prompt, ...imageParts]);
      const text = response?.response?.text?.() || response?.text || '';
      return normalizeResult(extractJson(text), lang);
    } catch (error) {
      const details = String(error?.message || error || '');
      if (details.includes('API_KEY_SERVICE_BLOCKED') || details.includes('firebasevertexai.googleapis.com')) {
        throw new Error(
          lang === 'ar'
            ? 'Gemini غير مُصرّح لهذا المفتاح. من Google Cloud Console أزل تقييد المفتاح أو اسمح بخدمة Firebase Vertex AI API (firebasevertexai.googleapis.com)، ثم أعد المحاولة.'
            : 'Gemini is not authorized for this API key. In Google Cloud Console, remove the key restriction or allow Firebase Vertex AI API (firebasevertexai.googleapis.com), then try again.'
        );
      }
      throw error;
    }
  }

  window.SidarAI = {
    async generateAnalysis(formData, files, lang = 'en', catalog = {}) {
      return await generateWithFirebase(formData, files, lang, catalog);
    },
  };
})();
